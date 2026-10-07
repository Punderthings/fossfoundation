#!/usr/bin/env ruby
# frozen_string_literal: true

module SponsorUtils
  DESCRIPTION = <<-HEREDOC
  SponsorUtils: good-enough scrapers and detectors of FOSS sponsors.
    Run from project root directory.  With no options, parses every
    _sponsorships/*.md model and writes _data/sponsorships/<org>.json.
    If an org fails to parse, its existing JSON file is left untouched,
    errors are reported on stderr, and the exit code is nonzero.
    Requires the nokogiri gem; uses Ruby 3.3+ stdlib otherwise.
  HEREDOC
  module_function
  require 'yaml'
  require 'json'
  require 'net/http'
  require 'uri'
  require 'nokogiri'
  require 'date'
  require 'optparse'

  # NOTE OWASP parsing css may be fragile; relies on nth-of-type
  # TODO: Eclipse dom parsing:
  #   div.eclipsefdn-members-list ... a with href and title that has sponsor name
  #   Member page: div.member-detail a

  # Map all sponsorships to common-ish levels
  # - Ordinals are cash sponsorships in order
  # - 'inkind'* is services donations (primarily services, not cash)
  # - community is widely used as a separate level
  # - grants covers any sort of government/institution grants
  # TODO: Define a more rigorous and smaller set of categories,
  #   to map some unusual ones (cncf:enduser, etc.) to simpler ones
  SPONSOR_METALEVELS = %w[ first second third fourth fifth sixth seventh eighth community firstinkind secondinkind thirdinkind fourthinkind startuppartners academic enduser grants ]
  CURRENT_SPONSORSHIP = '20240101' # HACK: select current one TODO allow different dates/versions
  SPONSORSHIPS_DIR = '_sponsorships'
  DEFAULT_OUTDIR = '_data/sponsorships'
  PARSE_DATE = 'parseDate'

  # Hostnames that are known to belong to a single sponsor org; whole-host matches only
  # TODO: consider removing ^cloud. from: google baidu tencent
  # TODO: consider removing ^aws. from amazon ^azure. from microsoft
  # TODO: consider removing ^group. from mercedes-benz
  # TODO: consider removing ^en. from various urls
  HOST_ALIASES = {
    'opensource.google' => 'google.com',
    'opensource.google.com' => 'google.com',
    'techatbloomberg.com' => 'bloomberg.com',
    'opensource.twosigma.com' => 'twosigma.com',
    'opensource.salesforce.com' => 'salesforce.com'
  }.freeze

  # Network and file safety limits
  USER_AGENT = 'fossfoundation.info sponsor research (+https://github.com/Punderthings/fossfoundation)'
  OPEN_TIMEOUT = 15 # seconds
  READ_TIMEOUT = 60 # seconds
  MAX_REDIRECTS = 5
  MAX_RETRIES = 2 # Retries after the first attempt, for timeouts / 429 / 5xx only
  MAX_FETCH_BYTES = 20 * 1024 * 1024 # Largest known source (LF landscape.yml) is ~3.3MB
  MAX_SUBPAGES = 250 # Per-org cap on per-sponsor subpage fetches
  SUBPAGE_DELAY = 0.5 # seconds between subpage fetches, to be polite
  ORG_ID_PATTERN = /\A[a-z0-9][a-z0-9_-]*\z/
  DOMAIN_PATTERN = %r{\A[a-z0-9-]+(\.[a-z0-9-]+)+(/.*)?\z}i

  # Raised for any problem that means an org's sponsor data is not trustworthy;
  # callers should report it and not overwrite previously parsed data.
  class ParseError < StandardError; end

  # @return true if verbose logging is on
  def verbose?
    @verbose == true
  end

  # @param value true to enable verbose logging to stdout
  def verbose=(value)
    @verbose = value
  end

  # Log a progress message to stdout when verbose
  def log(msg)
    puts msg if verbose?
  end

  # Report a non-fatal problem on stderr; output is still written
  def warn_msg(msg)
    warn "WARNING: #{msg}"
  end

  # Coerce YAML config values like 'true', 'false', true, nil into a boolean
  # Front matter often has quoted strings, where 'false' would otherwise be truthy
  # @param value from YAML
  # @return boolean
  def as_bool(value)
    case value
    when true, false then value
    when nil then false
    else %w[true yes y 1 on].include?(value.to_s.strip.downcase)
    end
  end

  # Return a normalized domain name for mapping to a single sponsor org
  # Only the host is transformed; paths, queries, ports are dropped
  # @param href url (or bare domain) to normalize
  # @return a good enough normalized hostname; or the stripped input if not a recognizable web url
  def normalize_href(href)
    str = href.to_s.strip
    return str if str.empty?
    str = "https://#{str}" if DOMAIN_PATTERN.match?(str) # Bare domain like example.com
    uri = URI.parse(str)
    host = uri.host.to_s.downcase.delete_suffix('.').delete_prefix('www.')
    return href.to_s.strip if host.empty?
    return HOST_ALIASES.fetch(host, host)
  rescue URI::Error
    return href.to_s.strip
  end

  # Clean up one level's list of sponsors: drop blanks and duplicates
  # @param ary of sponsor strings
  # @return cleaned array
  def clean_list(ary)
    ary.map { |s| s.to_s.strip }.reject(&:empty?).uniq
  end

  # Fetch a url over http(s) with timeouts, retries, redirects, and a size cap
  # @param url to fetch
  # @return response body as string
  # @raise ParseError if the url cannot be fetched
  def fetch(url, redirects: MAX_REDIRECTS)
    uri = URI.parse(url.to_s)
    raise ParseError, "fetch(#{url}): only http(s) urls are supported" unless uri.is_a?(URI::HTTP) && uri.host
    (1..MAX_RETRIES + 1).each do |attempt|
      log("fetch(#{uri})")
      begin
        status, body, location = fetch_once(uri)
      rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, Errno::ECONNREFUSED, EOFError => e
        status = e.message
      rescue ParseError
        raise
      rescue StandardError => e # DNS, TLS, and other socket errors
        raise ParseError, "fetch(#{uri}): #{e.class}: #{e.message}"
      end
      case status
      when :ok
        return body
      when :redirect
        raise ParseError, "fetch(#{url}): too many redirects" if redirects <= 0
        return fetch(URI.join(uri, location.to_s).to_s, redirects: redirects - 1)
      end
      # Rate limited, server error, or timeout: retry with backoff
      raise ParseError, "fetch(#{uri}): #{status} (after #{attempt} attempts)" if attempt > MAX_RETRIES
      sleep(2**(attempt - 1))
    end
  end

  # Perform one GET request
  # @return [status, body, location]; status is :ok, :redirect, or a retryable "code message" string
  # @raise ParseError on non-retryable http errors or oversize responses
  def fetch_once(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                    open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
      request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = USER_AGENT
      http.request(request) do |response|
        case response
        when Net::HTTPSuccess
          return [:ok, read_limited(response, uri), nil]
        when Net::HTTPRedirection
          return [:redirect, nil, response['location']]
        when Net::HTTPTooManyRequests, Net::HTTPServerError
          return ["#{response.code} #{response.message}", nil, nil]
        else
          raise ParseError, "fetch(#{uri}): #{response.code} #{response.message}"
        end
      end
    end
  end

  # Read a response body, refusing anything over MAX_FETCH_BYTES
  def read_limited(response, uri)
    if response['content-length'].to_i > MAX_FETCH_BYTES
      raise ParseError, "fetch(#{uri}): response too large (#{response['content-length']} bytes)"
    end
    body = +''
    response.read_body do |chunk|
      body << chunk
      raise ParseError, "fetch(#{uri}): response too large (> #{MAX_FETCH_BYTES} bytes)" if body.bytesize > MAX_FETCH_BYTES
    end
    return body
  end

  # Read a local file, with a size cap
  # @param path to read
  # @return file contents as string
  # @raise ParseError if missing or too large
  def read_local(path)
    raise ParseError, "read_local(#{path}): file not found" unless File.file?(path)
    raise ParseError, "read_local(#{path}): file too large" if File.size(path) > MAX_FETCH_BYTES
    return File.read(path, encoding: 'UTF-8')
  end

  # Scrape html sponsor listing defined by css selectors
  # Each level needs a 'selector' and 'attr'; levels without a selector are left empty
  # @param io html string (or IO) to parse
  # @param sponsorship level map of organization
  # @return hash of sponsors by approximate map-defined levels
  # @raise ParseError on an invalid css selector
  def scrape_bycss(io, sponsorship)
    sponsors = {}
    normalize = as_bool(sponsorship['normalize'])
    doc = Nokogiri::HTML5(io)
    sponsorship.fetch('levels', {}).each do |lvl, lvldata|
      sponsors[lvl] = []
      selector = lvldata['selector'].to_s.strip
      attr = lvldata['attr'].to_s.strip
      if selector.empty? || attr.empty?
        log("scrape_bycss(#{lvl}) no selector/attr configured; skipping level")
        next
      end
      begin
        nodelist = doc.css(selector)
      rescue Nokogiri::CSS::SyntaxError => e
        raise ParseError, "scrape_bycss(#{lvl}): invalid selector '#{selector}': #{e.message.lines.first&.strip}"
      end
      nodelist.each do |node|
        value = node[attr]
        sponsors[lvl] << ('href'.eql?(attr) && normalize ? normalize_href(value) : value)
      end
      sponsors[lvl] = clean_list(sponsors[lvl])
      warn_msg("scrape_bycss(#{lvl}): selector '#{selector}' matched no sponsors") if sponsors[lvl].empty?
    end
    return sponsors
  end

  # Unwrap landscape entries, which may be either flat or nested
  # Flat (landscape.yml standard):  - category:\n    name: X   => {'category' => nil, 'name' => 'X'}
  # Nested:                         - category:\n      name: X => {'category' => {'name' => 'X'}}
  def landscape_entry(hash, key)
    return {} unless hash.is_a?(Hash)
    return hash[key].is_a?(Hash) ? hash[key] : hash
  end

  # Parse a CNCF style landscape.yml for a sponsor list
  # Landscape homepage_urls are always normalized
  # @param io YAML string (or IO) to parse
  # @param sponsorship level map of organization
  # @return hash of sponsors by approximate map-defined levels
  # @raise ParseError if the configured category is not found
  def parse_landscape(io, sponsorship)
    category = sponsorship['landscape']
    begin
      landscape = YAML.safe_load(io, aliases: true)
    rescue Psych::Exception => e
      raise ParseError, "parse_landscape(#{category}): invalid YAML: #{e.message}"
    end
    categories = landscape.is_a?(Hash) ? Array(landscape['landscape']) : []
    found = categories.map { |h| landscape_entry(h, 'category') }.find { |h| category.eql?(h['name']) }
    raise ParseError, "parse_landscape(#{category}): category not found" unless found
    groups = Array(found['subcategories']).map { |h| landscape_entry(h, 'subcategory') }
    raise ParseError, "parse_landscape(#{category}): category has no subcategories" if groups.empty?
    levels = sponsorship.fetch('levels', {})
    name_to_level = levels.to_h { |lvl, h| [h.fetch('name', ''), lvl] }
    sponsors = levels.keys.to_h { |lvl| [lvl, []] }
    groups.each do |group|
      level = name_to_level[group['name']]
      unless level
        warn_msg("parse_landscape(#{category}): subcategory '#{group['name']}' matches no configured level; skipping")
        next
      end
      Array(group['items']).each do |h|
        item = landscape_entry(h, 'item')
        sponsors[level] << normalize_href(item.fetch('homepage_url', nil) || item['name'])
      end
    end
    sponsors.each do |lvl, ary|
      sponsors[lvl] = clean_list(ary)
      warn_msg("parse_landscape(#{category}): level '#{lvl}' (#{levels[lvl]['name']}) has no sponsors") if sponsors[lvl].empty?
    end
    return sponsors
  end

  # Cleanup sponsor lists that are IDs not domains
  # Non-array values (like parseDate) are passed through unchanged
  # @param links hash of detected sponsor ids
  # @param mapname filename of json mapping to read, from 'sponsormap'
  # @return sponsors hash normalized to domain names
  # @raise ParseError if the map cannot be read
  def cleanup_with_map(links, mapname)
    begin
      map = JSON.parse(read_local(mapname))
    rescue JSON::ParserError => e
      raise ParseError, "cleanup_with_map(#{mapname}): #{e.message}"
    end
    sponsors = {}
    links.each do |level, ary|
      sponsors[level] = ary.is_a?(Array) ? clean_list(ary.map { |itm| map.fetch(itm, nil) || normalize_href(itm) }) : ary
    end
    return sponsors
  end

  # Parse separate per-sponsor pages used by some orgs
  # Entries that are already absolute urls are normalized; others are fetched
  # relative to 'sponsorroot' and the 'sponsorselector' href is used.
  # @param existing_sponsors hash of previously detected sponsor links
  # @param sponsorship definition hash with 'sponsorroot', 'sponsorselector'
  # @return sponsors hash normalized to domain names
  def parse_subpages(existing_sponsors, sponsorship)
    sponsors = {}
    rooturl = sponsorship['sponsorroot']
    selector = sponsorship['sponsorselector']
    fetches = 0
    existing_sponsors.each do |level, ary|
      next unless ary.is_a?(Array)
      sponsors[level] = []
      ary.each do |itm|
        if itm.downcase.start_with?('http')
          sponsors[level] << normalize_href(itm)
          next
        end
        if fetches >= MAX_SUBPAGES
          warn_msg("parse_subpages: reached #{MAX_SUBPAGES} subpage limit; skipping #{itm}")
          next
        end
        sleep(SUBPAGE_DELAY) if fetches.positive?
        fetches += 1
        begin
          node = Nokogiri::HTML5(fetch(URI.join(rooturl, itm).to_s)).at_css(selector)
          if node && node['href']
            sponsors[level] << normalize_href(node['href'])
          else
            warn_msg("parse_subpages(#{itm}): selector '#{selector}' not found; skipping")
          end
        rescue ParseError, URI::Error => e
          warn_msg("parse_subpages(#{itm}): #{e.message}; skipping")
        end
      end
      sponsors[level] = clean_list(sponsors[level])
    end
    return sponsors
  end

  # Future use: allow parsing historical sponsorships
  def get_current_sponsorship(sponsorship)
    return sponsorship # TODO refactor for use with yaml frontmatter in .md files (or drop feature)
  end

  # Process single sponsorship lookup
  # Processing varies depending on landscape, sponsorselector, sponsormap attrs
  # Parse either live url, or override with a path reference (for cached/historical data)
  # @param org id of org being parsed
  # @param sponsorship parsed _sponsorship hash defining what to do
  # @param cachefile optional filepath to local html to parse
  # @return processed hash of sponsors
  # @raise ParseError if the org's data could not be parsed
  def parse_sponsorship(org, sponsorship, cachefile = nil)
    sponsorurl = sponsorship['sponsorurl']
    raise ParseError, "parse_sponsorship(#{org}): no sponsorurl or staticmap defined" unless cachefile || sponsorurl
    io = cachefile ? read_local(cachefile) : fetch(sponsorurl)
    # Parse a landscape.yml, or scrape a webpage by css
    if sponsorship['landscape']
      sponsors = parse_landscape(io, sponsorship)
    else
      sponsors = scrape_bycss(io, sponsorship)
    end
    # Custom post-processing for various orgs
    sponsors = parse_subpages(sponsors, sponsorship) if sponsorship['sponsorselector']
    sponsors = cleanup_with_map(sponsors, sponsorship['sponsormap']) if sponsorship['sponsormap']
    if sponsors.values.none? { |ary| ary.is_a?(Array) && !ary.empty? }
      raise ParseError, "parse_sponsorship(#{org}): no sponsors found in #{cachefile || sponsorurl}; page layout may have changed"
    end
    return sponsors
  end

  # Copy over a static map of sponsors for an org
  # @param org id of org being parsed
  # @param sponsorship parsed _sponsorship hash with static sponsor arys
  # @return processed hash of sponsors
  def mapped_sponsorship(org, sponsorship)
    sponsors = {}
    sponsorship.fetch('levels', {}).each do |lvl, hash|
      sponsors[lvl] = Array(hash['sponsors'])
    end
    return sponsors
  end

  # Process one sponsorship mapping
  # @param org id of org being processed
  # @param sponsorship parsed _sponsorship hash
  # @param cachefile optional filepath to local html to parse
  # @return processed hash of sponsors
  # @raise ParseError if the org's data could not be parsed
  def process_sponsorship(org, sponsorship, cachefile = nil)
    staticmap = sponsorship['staticmap']
    log("process_sponsorship(#{org}...) #{staticmap ? 'static map' : 'parsing url'}")
    if staticmap
      sponsors = mapped_sponsorship(org, sponsorship)
      sponsors[PARSE_DATE] = staticmap
    else
      sponsors = parse_sponsorship(org, sponsorship, cachefile)
      sponsors[PARSE_DATE] = Date.today.strftime('%Y%m%d')
    end
    return sponsors
  end

  # Process a list of sponsorship maps; one org failing does not stop others
  # TODO future use: allow historical sponsorship maps via get_current_sponsorship
  # @param sponsorships hash of org => _sponsorship hashes
  # @param failures hash that will be filled with org => error message
  # @return hash of orgs => {sponsors...} for successfully parsed orgs only
  def process_sponsorships(sponsorships, failures = {})
    all_sponsors = {}
    sponsorships.each do |org, sponsorship|
      all_sponsors[org] = process_sponsorship(org, get_current_sponsorship(sponsorship))
    rescue ParseError => e
      failures[org] = e.message
    end
    return all_sponsors
  end

  # Convenience method; parses every _sponsorships/*.md model
  # @param failures hash that will be filled with org => error message
  # @return hash of orgs => {sponsors...} for successfully parsed orgs only
  def process_all_sponsorships(failures = {})
    all_sponsor_models = {}
    Dir.glob(File.join(SPONSORSHIPS_DIR, '*.md')).sort.each do |file|
      org = File.basename(file, '.md')
      all_sponsor_models[org] = get_sponsorship_file(org)
    rescue ParseError => e
      failures[org] = e.message
    end
    return process_sponsorships(all_sponsor_models, failures)
  end

  # Get a sponsorship model by org id from _sponsorships/<org>.md front matter
  # @param org id of org
  # @return hash of sponsorship model
  # @raise ParseError if the org id is invalid or the file is missing or malformed
  def get_sponsorship_file(org)
    raise ParseError, "get_sponsorship_file(#{org}): invalid org id" unless ORG_ID_PATTERN.match?(org.to_s)
    text = read_local(File.join(SPONSORSHIPS_DIR, "#{org}.md"))
    frontmatter = text[/\A---\s*\n(.*?)^---\s*$/m, 1] || text
    data = YAML.safe_load(frontmatter, permitted_classes: [Date], aliases: true)
    raise ParseError, "get_sponsorship_file(#{org}): front matter is not a hash" unless data.is_a?(Hash)
    return data
  rescue Psych::Exception => e
    raise ParseError, "get_sponsorship_file(#{org}): invalid YAML: #{e.message}"
  end

  # Write one org's sponsor hash as JSON
  def write_sponsors(path, sponsors)
    File.write(path, JSON.pretty_generate(sponsors))
  end

  # Print any failures to stderr
  # @return exit code: 0 if no failures, 1 otherwise
  def report_failures(failures)
    return 0 if failures.empty?
    warn "ERROR: #{failures.size} sponsorship(s) failed; existing output left unchanged:"
    failures.each { |org, msg| warn "  #{org}: #{msg}" }
    return 1
  end

  # ## ### #### ##### ######
  # Check commandline options
  def parse_commandline(argv = ARGV)
    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options]"
      opts.on('-h', '--help') { puts "#{DESCRIPTION}\n#{opts}"; exit }
      opts.on('--out OUTPUT', "Output directory (default #{DEFAULT_OUTDIR}), or filename with --one.") do |out|
        options[:out] = out
      end
      opts.on('-oORGID', '--one ORGID', 'Input org id (asf, python, etc.) to parse one.') do |orgid|
        options[:orgid] = orgid
      end
      opts.on('-iINFILE', '--in INFILE', 'Input local filename to parse for one org.') do |infile|
        options[:infile] = infile
      end
      opts.on('-mMAPID', '--map MAPID', 'Lint one existing sponsorship with its map.') do |mapid|
        options[:mapid] = mapid
      end
      opts.on('-v', '--[no-]verbose', 'Verbose output to stdout.') do |v|
        options[:verbose] = v
      end
      begin
        opts.parse!(argv)
      rescue OptionParser::ParseError => e
        $stderr.puts e
        $stderr.puts opts
        exit 1
      end
      if options[:infile] && !options[:orgid]
        $stderr.puts '--in requires --one ORGID'
        exit 1
      end
    end
    return options
  end

  # Resolve where to write one org's JSON
  # @param out user-supplied --out (directory or filename), or nil
  # @param org id
  # @return output filepath
  def output_path(out, org)
    return File.join(DEFAULT_OUTDIR, "#{org}.json") unless out
    return File.directory?(out) ? File.join(out, "#{org}.json") : out
  end

  # ### #### ##### ######
  # Main method for command line use
  # @return exit code
  def main(argv = ARGV)
    options = parse_commandline(argv)
    self.verbose = options.fetch(:verbose, false)
    failures = {}
    if (mapid = options[:mapid])
      raise ParseError, "--map: invalid id #{mapid}" unless ORG_ID_PATTERN.match?(mapid)
      sponsor_file = File.join(DEFAULT_OUTDIR, "#{mapid}.json")
      links = JSON.parse(read_local(sponsor_file))
      write_sponsors(sponsor_file, cleanup_with_map(links, File.join('_data', "#{mapid}_map.json")))
    elsif (orgid = options[:orgid])
      sponsorship = get_current_sponsorship(get_sponsorship_file(orgid))
      parsed = process_sponsorship(orgid, sponsorship, options[:infile])
      write_sponsors(output_path(options[:out], orgid), parsed)
    else
      outdir = options.fetch(:out, DEFAULT_OUTDIR)
      raise ParseError, "--out #{outdir} must be an existing directory" unless File.directory?(outdir)
      process_all_sponsorships(failures).each do |org, sponsors|
        log("Writing #{org}")
        write_sponsors(File.join(outdir, "#{org}.json"), sponsors)
      end
    end
    return report_failures(failures)
  rescue ParseError, JSON::ParserError => e
    warn "ERROR: #{e.message}"
    return 1
  end

  exit(main) if __FILE__ == $PROGRAM_NAME
end
