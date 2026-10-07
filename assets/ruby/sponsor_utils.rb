#!/usr/bin/env ruby
# frozen_string_literal: true

module SponsorUtils
  DESCRIPTION = <<-HEREDOC
  SponsorUtils: good-enough scrapers and detectors of FOSS sponsors.
    Run from project root directory.  With no options, parses every
    _sponsorships/*.md model and writes _data/sponsorships/<org>.json.
    If an org fails to parse, or its sponsor count drops suspiciously,
    its existing JSON file is left untouched, errors are reported on
    stderr, and the exit code is nonzero (use --force to accept drops).

    Source types (sourcetype: in the model; inferred if absent):
      css            Scrape sponsorurl html with per-level css selector/attr
                     (add render: chrome for pages built by JavaScript)
      landscape      CNCF-style landscape.yml; 'landscape' names the category
      landscapejson  landscape2 site data/full.json; 'landscape' names the category
      json           Any JSON API; see the 'json' key for field paths
      static         Hand-maintained levels.*.sponsors lists (staticmap: date)

    --check compares each org's committed data with a fresh parse and
    reports stale, changed, or failing orgs (exit 1 if any); it never writes.

    History: when an org's sponsor list changes, the change is added to
    history/sponsorships/<org>.json as sponsor spans (sponsor, level,
    firstSeen, lastSeen); unchanged runs only update lastChecked in the
    current file.  --backfill-git builds history from committed versions.

    Requires the nokogiri and public_suffix gems (public_suffix is
    already in Gemfile.lock via jekyll); Ruby 3.3+ stdlib otherwise.
    render: chrome additionally needs a local Chrome/Chromium (or CHROME_BIN).
  HEREDOC
  module_function
  require 'yaml'
  require 'json'
  require 'net/http'
  require 'uri'
  require 'date'
  require 'optparse'
  require 'tmpdir'
  require 'fileutils'
  require 'io/wait'
  require 'open3'
  begin
    require 'nokogiri'
    require 'public_suffix'
  rescue LoadError => e
    abort "SponsorUtils requires the nokogiri and public_suffix gems (#{e.message}); try: gem install nokogiri public_suffix"
  end

  # NOTE OWASP parsing css may be fragile; relies on nth-of-type

  # Map all sponsorships to common-ish levels
  # - Ordinals are cash sponsorships in order
  # - 'inkind'* is services donations (primarily services, not cash)
  # - community is widely used as a separate level
  # - grants covers any sort of government/institution grants
  # TODO: Define a more rigorous and smaller set of categories,
  #   to map some unusual ones (cncf:enduser, etc.) to simpler ones
  SPONSOR_METALEVELS = %w[ first second third fourth fifth sixth seventh eighth community firstinkind secondinkind thirdinkind fourthinkind startuppartners academic enduser grants ]
  SPONSORSHIPS_DIR = '_sponsorships'
  DEFAULT_OUTDIR = '_data/sponsorships'
  PARSE_DATE = 'parseDate'
  EFFECTIVE_DATE = 'effectiveDate'
  PAST_MODELS = 'pastModels'
  LAST_CHECKED = 'lastChecked'
  DEFAULT_HISTORY_DIR = 'history/sponsorships'
  ALL_SPONSORSHIPS_FILE = '_data/allsponsorships.json' # Early 2024 combined data, used by --backfill-git
  SOURCE_TYPES = %w[css landscape landscapejson json static].freeze

  # Editable list of hostnames/domains that belong to one sponsor org; see file for format
  HOST_ALIASES_FILE = File.expand_path('../../_data/host_aliases.json', __dir__)

  # Network and file safety limits
  USER_AGENT = 'fossfoundation.info sponsor research (+https://github.com/Punderthings/fossfoundation)'
  OPEN_TIMEOUT = 15 # seconds
  READ_TIMEOUT = 60 # seconds
  MAX_REDIRECTS = 5
  MAX_RETRIES = 2 # Retries after the first attempt, for timeouts / 429 / 5xx only
  MAX_FETCH_BYTES = 20 * 1024 * 1024 # Largest known source (LF landscape full.json) is ~6.5MB
  MAX_SUBPAGES = 250 # Per-org cap on per-sponsor subpage fetches
  SUBPAGE_DELAY = 0.5 # seconds between subpage fetches, to be polite
  ORG_ID_PATTERN = /\A[a-z0-9][a-z0-9_-]*\z/
  DOMAIN_PATTERN = %r{\A[a-z0-9-]+(\.[a-z0-9-]+)+(/.*)?\z}i

  # Headless browser rendering (render: chrome)
  RENDER_TIMEOUT = 90 # seconds for the whole browser run
  RENDER_BUDGET_MS = 15_000 # virtual time Chrome lets page scripts run before dumping the DOM
  CHROME_CANDIDATES = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/Applications/Chromium.app/Contents/MacOS/Chromium',
    'google-chrome', 'google-chrome-stable', 'chromium', 'chromium-browser'
  ].freeze

  # Pages served instead of content by bot-detection services; we never try to get past these
  CHALLENGE_TITLES = /\A\s*(client challenge|just a moment|attention required|access denied|verifying you are human|are you a robot)/i
  CHALLENGE_MARKERS = %r{/cdn-cgi/challenge-platform/|id=["']challenge-form["']|captcha-delivery\.com}i

  # Drift guard: refuse to overwrite existing data when a fresh parse loses this much
  DRIFT_MIN_TOTAL = 10 # only judge totals for orgs with at least this many sponsors
  DRIFT_MIN_RATIO = 0.5 # new total below this fraction of old total is suspicious
  DRIFT_MIN_LEVEL = 5 # a level that had at least this many sponsors and is now empty is suspicious
  DEFAULT_MAX_AGE = 365 # days before --check calls committed data stale

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

  # ## ### #### ##### ######
  # Hostname normalization

  # @return hash of host or registrable domain => canonical sponsor domain
  def host_aliases
    @host_aliases ||= begin
      JSON.parse(File.read(HOST_ALIASES_FILE)).fetch('aliases', {}).to_h { |k, v| [k.downcase, v.downcase] }
    rescue Errno::ENOENT, JSON::ParserError => e
      warn_msg("host_aliases(#{HOST_ALIASES_FILE}): #{e.message}; no aliases applied")
      {}
    end
  end

  # Collapse a hostname to its registrable domain using the Public Suffix List
  # e.g. automotive.panasonic.com => panasonic.com; foo.co.uk stays; bar.github.io stays
  # @param host lowercase hostname
  # @return registrable domain, or host unchanged if it has none (IPs, bare suffixes)
  def registrable_domain(host)
    return host if host.match?(/\A[\d.]+\z/) || host.include?(':') # IP addresses
    PublicSuffix.domain(host, list: public_suffix_list) || host
  rescue PublicSuffix::Error
    host
  end

  # The Public Suffix List bundled with the gem, read as UTF-8 regardless of locale
  # (the gem's own loader fails when LANG is unset, as in cron or minimal CI shells)
  def public_suffix_list
    @public_suffix_list ||= PublicSuffix::List.parse(File.read(PublicSuffix::List::DEFAULT_LIST_PATH, encoding: 'UTF-8'))
  end

  # Map a hostname to one canonical domain per sponsor org
  # Exact host aliases win, then aliases for its registrable domain, then '.tld' brand aliases
  # @param host lowercase hostname
  # @return canonical domain
  def canonical_host(host)
    return host_aliases[host] if host_aliases.key?(host)
    domain = registrable_domain(host)
    return host_aliases[domain] if host_aliases.key?(domain)
    return host_aliases.fetch(".#{domain.split('.').last}", domain)
  end

  # Return a normalized domain name for mapping to a single sponsor org
  # Only the host is used; paths, queries, ports are dropped, and subdomains
  # are merged into their registrable domain (with aliases from HOST_ALIASES_FILE)
  # @param href url (or bare domain) to normalize
  # @return a good enough normalized domain; or the stripped input if not a recognizable web url
  def normalize_href(href)
    str = href.to_s.strip
    return str if str.empty?
    str = "https://#{str}" if DOMAIN_PATTERN.match?(str) # Bare domain like example.com
    uri = URI.parse(str)
    host = uri.host.to_s.downcase.delete_suffix('.').delete_prefix('www.')
    return href.to_s.strip if host.empty?
    return canonical_host(host)
  rescue URI::Error
    return href.to_s.strip
  end

  # Clean up one level's list of sponsors: drop blanks and duplicates
  # @param ary of sponsor strings
  # @return cleaned array
  def clean_list(ary)
    ary.map { |s| s.to_s.strip }.reject(&:empty?).uniq
  end

  # Re-apply current normalization to previously parsed sponsor data
  # Entries that look like domains are normalized; names and ids are kept as-is
  # @param sponsors hash of level => array (other keys passed through)
  # @return renormalized hash
  def renormalize(sponsors)
    sponsors.transform_values do |ary|
      next ary unless ary.is_a?(Array)
      clean_list(ary.map { |s| DOMAIN_PATTERN.match?(s.to_s.strip) ? normalize_href(s) : s })
    end
  end

  # ## ### #### ##### ######
  # Fetching

  # Fetch a url over http(s) with timeouts, retries, redirects, and a size cap
  # @param url to fetch
  # @return response body as string
  # @raise ParseError if the url cannot be fetched
  def fetch(url, redirects: MAX_REDIRECTS)
    uri = parse_http_uri(url)
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

  # @return URI::HTTP for an http(s) url
  # @raise ParseError for anything else
  def parse_http_uri(url)
    uri = URI.parse(url.to_s)
    raise ParseError, "fetch(#{url}): only http(s) urls are supported" unless uri.is_a?(URI::HTTP) && uri.host
    return uri
  rescue URI::Error => e
    raise ParseError, "fetch(#{url}): #{e.message}"
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

  # Find a Chrome or Chromium executable
  # @return path to executable
  # @raise ParseError if none found
  def chrome_path
    candidates = [ENV.fetch('CHROME_BIN', nil), *CHROME_CANDIDATES].compact
    candidates.each do |candidate|
      return candidate if candidate.include?('/') && File.executable?(candidate)
      found = ENV.fetch('PATH', '').split(File::PATH_SEPARATOR).map { |dir| File.join(dir, candidate) }.find { |p| File.executable?(p) }
      return found if found
    end
    raise ParseError, 'render: chrome needs Chrome or Chromium installed (or set CHROME_BIN)'
  end

  # Render a JavaScript-built page in headless Chrome and return the resulting DOM
  # Uses Chrome's own --dump-dom so no browser-driver gem is needed.  The page is
  # requested with our normal, honest User-Agent; this is for sites that build
  # their sponsor list client-side, not for getting past bot detection.
  # Chrome may keep running after printing the DOM (seen on macOS), so we stop
  # reading at the closing </html> and then end Chrome's whole process group.
  # @param url to render
  # @return rendered html string
  # @raise ParseError on any failure or timeout
  def render_page(url)
    uri = parse_http_uri(url)
    log("render_page(#{uri})")
    Dir.mktmpdir('sponsor-utils-chrome') do |profile|
      cmd = [chrome_path, '--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check',
             '--disable-extensions', "--user-data-dir=#{profile}", "--user-agent=#{USER_AGENT}",
             "--virtual-time-budget=#{RENDER_BUDGET_MS}", '--dump-dom', uri.to_s]
      reader, writer = IO.pipe
      pid = Process.spawn(*cmd, out: writer, err: File::NULL, in: File::NULL, pgroup: true)
      writer.close
      html = read_dom(reader, uri)
      raise ParseError, "render_page(#{uri}): browser produced no output" if html.strip.empty?
      return html
    rescue SystemCallError => e
      raise ParseError, "render_page(#{uri}): could not run browser: #{e.message}"
    ensure
      reader&.close
      writer&.close unless writer&.closed?
      stop_process_group(pid) if pid
    end
  end

  # Read a dumped DOM until </html>, end of output, or RENDER_TIMEOUT
  # @raise ParseError on timeout or oversize output
  def read_dom(reader, uri)
    html = +''
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + RENDER_TIMEOUT
    loop do
      remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
      raise ParseError, "render_page(#{uri}): timed out after #{RENDER_TIMEOUT}s" if remaining <= 0 || !reader.wait_readable(remaining)
      chunk = reader.read_nonblock(65_536, exception: false)
      break if chunk.nil? # Browser closed its output
      next if chunk == :wait_readable
      html << chunk
      raise ParseError, "render_page(#{uri}): rendered page too large" if html.bytesize > MAX_FETCH_BYTES
      break if html.rstrip.end_with?('</html>')
    end
    return html
  end

  # Kill a spawned process and everything in its process group, then reap it
  def stop_process_group(pid)
    Process.kill('KILL', -pid)
  rescue Errno::ESRCH, Errno::EPERM
    nil
  ensure
    begin
      Process.wait(pid)
    rescue Errno::ECHILD
      nil
    end
  end

  # @return true if html is a bot-detection interstitial rather than real content
  def challenge_page?(doc, html)
    CHALLENGE_TITLES.match?(doc.at_css('title')&.text.to_s) || CHALLENGE_MARKERS.match?(html.to_s)
  end

  # ## ### #### ##### ######
  # Parsers for each source type

  # Which kind of source a sponsorship model describes
  # @param sponsorship model hash
  # @return one of SOURCE_TYPES
  # @raise ParseError on an unknown sourcetype
  def source_type(sponsorship)
    type = sponsorship['sourcetype'].to_s.strip.downcase
    if type.empty?
      return 'static' if sponsorship['staticmap']
      return 'landscape' if sponsorship['landscape']
      return 'css'
    end
    raise ParseError, "unknown sourcetype '#{type}' (expected one of #{SOURCE_TYPES.join(', ')})" unless SOURCE_TYPES.include?(type)
    return type
  end

  # Build a matcher from external level names to our level keys
  # Each level matches its 'match' value(s) if present, else its 'name'; case-insensitive
  # @param levels hash from sponsorship model
  # @return lambda taking an array of candidate names, returning a level key or nil
  def level_matcher(levels)
    table = levels.map { |lvl, h| [lvl, Array(h['match'] || h['name']).map { |n| n.to_s.strip.downcase }] }
    lambda do |names|
      wanted = Array(names).map { |n| n.to_s.strip.downcase }
      table.find { |_lvl, matches| wanted.intersect?(matches) }&.first
    end
  end

  # Warn once per unmatched external level name, with counts
  def warn_unmatched(context, unmatched)
    unmatched.tally.each do |name, count|
      warn_msg("#{context}: '#{name}' (#{count} sponsors) matches no configured level; skipping")
    end
  end

  # Warn for configured levels that ended up empty
  def warn_empty_levels(context, sponsors, levels)
    sponsors.each do |lvl, ary|
      warn_msg("#{context}: level '#{lvl}' (#{levels[lvl]['name']}) has no sponsors") if ary.empty?
    end
  end

  # Scrape html sponsor listing defined by css selectors
  # Each level needs a 'selector' and 'attr'; levels without a selector are left empty
  # @param io html string (or IO) to parse
  # @param sponsorship level map of organization
  # @return hash of sponsors by approximate map-defined levels
  # @raise ParseError on an invalid css selector, or a bot-detection page
  def scrape_bycss(io, sponsorship)
    sponsors = {}
    normalize = as_bool(sponsorship['normalize'])
    html = io.respond_to?(:read) ? io.read : io
    doc = Nokogiri::HTML5(html)
    if challenge_page?(doc, html)
      raise ParseError, 'scrape_bycss: site returned a bot-detection challenge instead of content; ' \
                        'not attempting to bypass it (consider a JSON source or a staticmap)'
    end
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
  # Subcategory names are matched to levels by 'match' or 'name'
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
    matcher = level_matcher(levels)
    sponsors = levels.keys.to_h { |lvl| [lvl, []] }
    unmatched = []
    groups.each do |group|
      items = Array(group['items']).map { |h| landscape_entry(h, 'item') }
      level = matcher.call(group['name'])
      unless level
        unmatched.concat([group['name']] * items.size)
        next
      end
      items.each { |item| sponsors[level] << normalize_href(item['homepage_url'] || item['name']) }
    end
    warn_unmatched("parse_landscape(#{category})", unmatched)
    sponsors.transform_values! { |ary| clean_list(ary) }
    warn_empty_levels("parse_landscape(#{category})", sponsors, levels)
    return sponsors
  end

  # Field paths used to read a landscape2 data/full.json as a generic JSON source
  LANDSCAPEJSON_PATHS = { 'items' => 'items', 'url' => 'homepage_url', 'name' => 'name', 'level' => 'subcategory' }.freeze

  # Read values at a dotted path, flattening arrays along the way
  # e.g. dig_all({'levels' => [{'d' => 'A'}, {'d' => 'B'}]}, 'levels.d') => ['A', 'B']
  # @param obj parsed JSON
  # @param path dotted path; empty means obj itself
  # @return array of non-nil values found
  def dig_all(obj, path)
    path.to_s.split('.').reduce([obj]) do |nodes, key|
      nodes.flat_map { |node| node.is_a?(Array) ? node : [node] }
           .filter_map { |node| node.is_a?(Hash) ? node[key] : nil }
    end.flat_map { |v| v.is_a?(Array) ? v : [v] }.compact
  end

  # Parse a JSON list of sponsors, such as a landscape2 data/full.json or a membership API
  # Model 'json' hash keys (all dotted paths into the JSON):
  #   items: path to the array of sponsor objects (empty for a top-level array)
  #   url:   field with the sponsor's website (normalized)
  #   name:  fallback field when url is empty
  #   level: field whose value(s) are matched to levels by 'match' or 'name'
  #   filter: optional {path => value or [values]} that items must match
  # For landscapejson these default to the landscape2 layout, filtered to the 'landscape' category.
  # @param io JSON string
  # @param sponsorship model hash
  # @return hash of sponsors by approximate map-defined levels
  # @raise ParseError on invalid JSON or a missing items array
  def parse_json(io, sponsorship)
    config = sponsorship.fetch('json', {}) || {}
    if source_type(sponsorship) == 'landscapejson'
      config = LANDSCAPEJSON_PATHS.merge('filter' => { 'category' => sponsorship['landscape'] }).merge(config)
    end
    context = "parse_json(#{sponsorship['landscape'] || sponsorship['identifier']})"
    begin
      data = JSON.parse(io)
    rescue JSON::ParserError => e
      raise ParseError, "#{context}: invalid JSON: #{e.message[0, 200]}"
    end
    items = config['items'].to_s.empty? ? data : config['items'].split('.').reduce(data) { |node, key| node.is_a?(Hash) ? node[key] : nil }
    raise ParseError, "#{context}: no array of items at '#{config['items']}'" unless items.is_a?(Array)
    filters = (config['filter'] || {}).transform_values { |v| Array(v).map { |s| s.to_s.downcase } }
    items = items.select do |item|
      filters.all? { |path, wanted| dig_all(item, path).map { |v| v.to_s.downcase }.intersect?(wanted) }
    end
    raise ParseError, "#{context}: no items matched filter #{config['filter'].inspect}" if items.empty? && !filters.empty?
    levels = sponsorship.fetch('levels', {})
    matcher = level_matcher(levels)
    normalize = sponsorship.key?('normalize') ? as_bool(sponsorship['normalize']) : true
    sponsors = levels.keys.to_h { |lvl| [lvl, []] }
    unmatched = []
    items.each do |item|
      names = dig_all(item, config['level'])
      level = matcher.call(names)
      unless level
        unmatched << (names.empty? ? '(no level)' : names.join('/'))
        next
      end
      url = dig_all(item, config['url']).first.to_s.strip
      value = url.empty? ? dig_all(item, config['name']).first : url
      sponsors[level] << (normalize && !url.empty? ? normalize_href(url) : value)
    end
    warn_unmatched(context, unmatched)
    sponsors.transform_values! { |ary| clean_list(ary) }
    warn_empty_levels(context, sponsors, levels)
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

  # ## ### #### ##### ######
  # Processing sponsorship models

  # Normalize a date from YAML or JSON (20240115, '20240115', '2024-01-15', or a Date)
  # @return 'YYYYMMDD' string, or nil if blank
  # @raise ParseError if not a valid date
  def date_key(value)
    return value.strftime('%Y%m%d') if value.is_a?(Date)
    str = value.to_s.strip
    return nil if str.empty?
    raise ParseError, "invalid date '#{value}' (expected YYYYMMDD)" unless str.match?(/\A\d{4}-?\d{2}-?\d{2}\z/)
    return Date.strptime(str.delete('-'), '%Y%m%d').strftime('%Y%m%d')
  rescue Date::Error
    raise ParseError, "invalid date '#{value}' (expected YYYYMMDD)"
  end

  # Select the sponsorship model in effect on a date
  # The model's own fields and levels are current from its effectiveDate.  Each
  # pastModels entry has an effectiveDate and lists only what differed from the
  # current model during its period: top-level fields (like levelurl) and per-level
  # fields (like name or amount).  A level set to null did not exist then.
  # @param sponsorship model hash from get_sponsorship_file
  # @param date anything date_key accepts; nil means the current model
  # @return model hash without pastModels; dates before the earliest known model get the earliest
  # @raise ParseError if effective dates are missing, invalid, duplicated, or out of order
  def model_at(sponsorship, date = nil)
    current = sponsorship.reject { |key, _| key == PAST_MODELS }
    past = sponsorship[PAST_MODELS]
    return current if past.nil? || past == []
    raise ParseError, "#{PAST_MODELS} must be a list" unless past.is_a?(Array)
    current_date = date_key(sponsorship[EFFECTIVE_DATE])
    raise ParseError, "#{PAST_MODELS} requires #{EFFECTIVE_DATE} on the current model" unless current_date
    versions = past.map do |entry|
      unless entry.is_a?(Hash) && date_key(entry[EFFECTIVE_DATE])
        raise ParseError, "each #{PAST_MODELS} entry needs an #{EFFECTIVE_DATE}"
      end
      [date_key(entry[EFFECTIVE_DATE]), entry]
    end.sort_by(&:first)
    dates = versions.map(&:first)
    raise ParseError, "#{PAST_MODELS} has duplicate #{EFFECTIVE_DATE} values" unless dates.uniq.size == dates.size
    raise ParseError, "#{PAST_MODELS} must all be earlier than #{EFFECTIVE_DATE} #{current_date}" if dates.last >= current_date
    wanted = date_key(date)
    return current if wanted.nil? || wanted >= current_date
    _, entry = versions.reverse.find { |d, _| d <= wanted } || versions.first
    return apply_past_model(current, entry)
  end

  # @return a copy of the current model with one pastModels entry's differences applied
  def apply_past_model(current, entry)
    model = Marshal.load(Marshal.dump(current))
    entry.each { |key, value| model[key] = value unless key == 'levels' }
    levels = (model['levels'] ||= {})
    (entry['levels'] || {}).each do |lvl, overrides|
      if overrides.nil?
        levels.delete(lvl)
      elsif overrides.is_a?(Hash)
        levels[lvl] = (levels[lvl] || {}).merge(overrides)
      else
        raise ParseError, "#{PAST_MODELS} level '#{lvl}' must be a hash or null"
      end
    end
    model[EFFECTIVE_DATE] = date_key(entry[EFFECTIVE_DATE])
    return model
  end

  # Get the raw source for a sponsorship: a local cache file, a rendered page, or a plain fetch
  def read_source(sponsorship, cachefile = nil)
    return read_local(cachefile) if cachefile
    url = sponsorship['sponsorurl']
    render = sponsorship['render'].to_s.strip.downcase
    return fetch(url) if render.empty? || render == 'none'
    raise ParseError, "unknown render '#{render}' (expected chrome)" unless render == 'chrome'
    return render_page(url)
  end

  # Process single sponsorship lookup
  # Processing varies depending on source type, sponsorselector, sponsormap attrs
  # Parse either live url, or override with a path reference (for cached/historical data)
  # @param org id of org being parsed
  # @param sponsorship parsed _sponsorship hash defining what to do
  # @param cachefile optional filepath to local html to parse
  # @return processed hash of sponsors
  # @raise ParseError if the org's data could not be parsed
  def parse_sponsorship(org, sponsorship, cachefile = nil)
    sponsorurl = sponsorship['sponsorurl']
    raise ParseError, "parse_sponsorship(#{org}): no sponsorurl or staticmap defined" unless cachefile || sponsorurl
    type = source_type(sponsorship)
    io = read_source(sponsorship, cachefile)
    sponsors = case type
               when 'landscape' then parse_landscape(io, sponsorship)
               when 'landscapejson', 'json' then parse_json(io, sponsorship)
               else scrape_bycss(io, sponsorship)
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
    static = source_type(sponsorship) == 'static'
    log("process_sponsorship(#{org}...) #{static ? 'static map' : 'parsing url'}")
    if static
      sponsors = mapped_sponsorship(org, sponsorship)
      sponsors[PARSE_DATE] = sponsorship['staticmap']
    else
      sponsors = parse_sponsorship(org, sponsorship, cachefile)
      sponsors[PARSE_DATE] = Date.today.strftime('%Y%m%d')
    end
    return sponsors
  end

  # Process a list of sponsorship maps; one org failing does not stop others
  # @param sponsorships hash of org => _sponsorship hashes
  # @param failures hash that will be filled with org => error message
  # @return hash of orgs => {sponsors...} for successfully parsed orgs only
  def process_sponsorships(sponsorships, failures = {})
    all_sponsors = {}
    sponsorships.each do |org, sponsorship|
      all_sponsors[org] = process_sponsorship(org, model_at(sponsorship))
    rescue ParseError => e
      failures[org] = e.message
    end
    return all_sponsors
  end

  # @return sorted array of org ids with a _sponsorships/<org>.md model
  def all_org_ids
    Dir.glob(File.join(SPONSORSHIPS_DIR, '*.md')).map { |f| File.basename(f, '.md') }.sort
  end

  # Convenience method; parses every _sponsorships/*.md model
  # @param failures hash that will be filled with org => error message
  # @return hash of orgs => {sponsors...} for successfully parsed orgs only
  def process_all_sponsorships(failures = {})
    all_sponsor_models = {}
    all_org_ids.each do |org|
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

  # ## ### #### ##### ######
  # Comparing, staleness, and drift

  # Load previously written sponsor data
  # @return hash, or nil if missing or unreadable
  def load_existing(path)
    return nil unless File.file?(path)
    return JSON.parse(read_local(path))
  rescue JSON::ParserError, ParseError
    return nil
  end

  # Age in days of a parseDate value like 20240115 or '20240115'
  # @return integer days, or nil if missing/unparseable
  def age_days(parse_date, today = Date.today)
    return nil if parse_date.to_s.strip.empty?
    return (today - Date.strptime(parse_date.to_s.strip, '%Y%m%d')).to_i
  rescue Date::Error
    return nil
  end

  # Compare two sponsor hashes level by level
  # @return hash of level => {old:, new:, added: [], removed: []} for every level in either
  def compare_sponsors(old, new)
    levels = (old.select { |_k, v| v.is_a?(Array) }.keys | new.select { |_k, v| v.is_a?(Array) }.keys)
    levels.to_h do |lvl|
      before = Array(old[lvl])
      after = Array(new[lvl])
      [lvl, { old: before.size, new: after.size, added: after - before, removed: before - after }]
    end
  end

  # @return array of reasons a fresh parse looks like a broken scrape rather than real change
  def drift_problems(old, new)
    return [] unless old
    diff = compare_sponsors(old, new)
    problems = diff.filter_map do |lvl, d|
      "level '#{lvl}' dropped from #{d[:old]} to 0" if d[:old] >= DRIFT_MIN_LEVEL && d[:new].zero?
    end
    old_total = diff.values.sum { |d| d[:old] }
    new_total = diff.values.sum { |d| d[:new] }
    if old_total >= DRIFT_MIN_TOTAL && new_total < old_total * DRIFT_MIN_RATIO
      problems << "total dropped from #{old_total} to #{new_total}"
    end
    return problems
  end

  # Refuse to overwrite existing data with a suspiciously smaller parse
  # @return true if problems were found but force was given
  # @raise ParseError unless force
  def guard_drift!(org, path, sponsors, force: false)
    problems = drift_problems(load_existing(path), sponsors)
    return false if problems.empty?
    message = "#{org}: suspicious drop vs #{path} (#{problems.join('; ')}); page layout may have changed"
    raise ParseError, "#{message}; use --force to write anyway" unless force
    warn_msg("#{message}; writing anyway (--force)")
    return true
  end

  # Check committed sponsor data for staleness and drift from a fresh parse
  # @param orgs array of org ids
  # @param outdir directory of committed json
  # @param max_age days before data is stale
  # @param offline true to only check ages, without fetching
  # @return array of result hashes {org:, statuses: [], age:, diff:, message:}
  def check_sponsorships(orgs, outdir: DEFAULT_OUTDIR, max_age: DEFAULT_MAX_AGE, offline: false, today: Date.today)
    orgs.map do |org|
      result = { org: org, statuses: [], age: nil, diff: nil, message: nil }
      old = load_existing(File.join(outdir, "#{org}.json"))
      if old
        result[:age] = age_days(old[LAST_CHECKED] || old[PARSE_DATE], today)
        result[:statuses] << 'stale' if result[:age].nil? || result[:age] > max_age
      else
        result[:statuses] << 'missing'
      end
      begin
        model = model_at(get_sponsorship_file(org))
        unless offline || source_type(model) == 'static'
          fresh = process_sponsorship(org, model)
          result[:diff] = compare_sponsors(old || {}, fresh)
          result[:statuses] << 'changed' if result[:diff].values.any? { |d| d[:added].any? || d[:removed].any? }
          problems = drift_problems(old, fresh)
          unless problems.empty?
            result[:statuses] << 'suspicious'
            result[:message] = problems.join('; ')
          end
        end
      rescue ParseError => e
        result[:statuses] << 'failed'
        result[:message] = e.message
      end
      result[:statuses] << 'ok' if result[:statuses].empty?
      result
    end
  end

  # Print --check results as a plain text table
  # @return exit code: 0 if every org is ok, 1 otherwise
  def report_check(results, max_age)
    results.each do |r|
      age = r[:age] ? "#{r[:age]}d" : '-'
      levels = (r[:diff] || {}).map do |lvl, d|
        d[:added].empty? && d[:removed].empty? ? "#{lvl}:#{d[:new]}" : "#{lvl}:#{d[:old]}->#{d[:new]}(+#{d[:added].size}/-#{d[:removed].size})"
      end
      line = format('%-16s %-24s age=%-6s %s', r[:org], r[:statuses].join(','), age, levels.join(' '))
      line += "\n    #{r[:message]}" if r[:message]
      puts line
    end
    bad = results.reject { |r| r[:statuses] == ['ok'] }
    puts "#{results.size} checked; #{bad.size} need attention (stale = lastChecked or parseDate older than #{max_age} days)"
    return bad.empty? ? 0 : 1
  end

  # ## ### #### ##### ######
  # Sponsor history: one file per org of sponsor spans, written when the current list changes
  #   {"org": "x",
  #    "scrapes": [{"parseDate", "lastChecked", "source", "modelDate", "forced", "counts"}, ...],
  #    "spans": [{"sponsor", "level", "firstSeen", "lastSeen"}, ...]}
  # A span covers consecutive scrapes listing a sponsor at a level: firstSeen is the
  # parseDate of the first, lastSeen the lastChecked of the last (null while current).
  # The current _data file's lastChecked is copied into history at the next change.

  # @return {level => sorted unique sponsors} for non-empty array levels
  def level_lists(sponsors)
    sponsors.each_with_object({}) do |(lvl, ary), lists|
      next unless ary.is_a?(Array)
      cleaned = clean_list(ary).sort
      lists[lvl] = cleaned unless cleaned.empty?
    end.sort.to_h
  end

  # @return path of an org's history file
  def history_path(history_dir, org)
    File.join(history_dir, "#{org}.json")
  end

  # @return parsed history hash, or nil if there is no file
  # @raise ParseError if the file exists but is unreadable
  def load_history(path)
    return nil unless File.file?(path)
    hist = JSON.parse(read_local(path))
    raise ParseError, "#{path}: not a sponsor history file" unless hist.is_a?(Hash) && hist['scrapes'].is_a?(Array) && hist['spans'].is_a?(Array)
    return hist
  rescue JSON::ParserError => e
    raise ParseError, "#{path}: #{e.message}"
  end

  # Rebuild the list of sponsors at each scrape from a history's spans
  # @return array of [scrape metadata hash, {level => sponsors}] in date order
  def history_states(hist)
    hist['scrapes'].sort_by { |scrape| scrape['parseDate'] }.map do |scrape|
      date = scrape['parseDate']
      active = hist['spans'].select { |span| span['firstSeen'] <= date && (span['lastSeen'].nil? || span['lastSeen'] >= date) }
      state = active.group_by { |span| span['level'] }.transform_values { |spans| spans.map { |span| span['sponsor'] }.sort }
      [scrape.reject { |key, _| key == 'counts' }, state.sort.to_h]
    end
  end

  # Build a history from a date-ordered list of scrapes and the sponsors each listed
  # @param entries array of [metadata with parseDate and lastChecked, {level => sponsors}]
  # @return history hash
  def build_history(org, entries)
    spans = []
    open = {}
    previous = nil
    entries.each do |meta, state|
      present = state.flat_map { |lvl, sponsors| sponsors.map { |sponsor| [sponsor, lvl] } }
      (open.keys - present).each do |key|
        open.delete(key)['lastSeen'] = previous['lastChecked'] || previous['parseDate']
      end
      present.each do |sponsor, lvl|
        next if open.key?([sponsor, lvl])
        span = { 'sponsor' => sponsor, 'level' => lvl, 'firstSeen' => meta['parseDate'], 'lastSeen' => nil }
        open[[sponsor, lvl]] = span
        spans << span
      end
      previous = meta
    end
    rank = ->(lvl) { SPONSOR_METALEVELS.index(lvl) || SPONSOR_METALEVELS.size }
    scrapes = entries.map do |meta, state|
      meta.slice('parseDate', 'lastChecked', 'source', 'modelDate', 'forced').compact
          .merge('counts' => state.transform_values(&:size))
    end
    return { 'org' => org, 'scrapes' => scrapes,
             'spans' => spans.sort_by { |span| [rank.call(span['level']), span['level'], span['sponsor'], span['firstSeen']] } }
  end

  # Serialize a history with one scrape or span per line, for readable diffs
  def history_json(hist)
    rows = ->(items) { items.empty? ? '[]' : "[\n    #{items.map { |item| JSON.generate(item) }.join(",\n    ")}\n  ]" }
    "{\n  \"org\": #{JSON.generate(hist['org'])},\n  \"scrapes\": #{rows.call(hist['scrapes'])},\n  \"spans\": #{rows.call(hist['spans'])}\n}\n"
  end

  # Write a history file, creating its directory
  def write_history(path, hist)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, history_json(hist))
  end

  # @return the day before a YYYYMMDD date, as YYYYMMDD
  def day_before(date)
    (Date.strptime(date, '%Y%m%d') - 1).strftime('%Y%m%d')
  end

  # Add a changed sponsor list to an org's history
  # @param old_current the org's previous current data (or nil), whose lastChecked dates the last scrape
  # @param meta scrape metadata with parseDate (and lastChecked, source, modelDate, forced)
  # @param state {level => sponsors} now listed
  # @raise ParseError if the history already has a later scrape
  def append_history(path, org, old_current, meta, state)
    hist = load_history(path)
    entries = hist ? history_states(hist) : []
    if old_current
      old_date = date_key(old_current[PARSE_DATE])
      old_state = level_lists(old_current)
      last = entries.last
      # Seed history with the previous current list when history is missing or behind it
      if old_date && !old_state.empty? && old_date < meta['parseDate'] && (last.nil? || (old_date > last[0]['parseDate'] && old_state != last[1]))
        entries << [{ 'parseDate' => old_date, 'lastChecked' => old_date, 'source' => 'previous' }, old_state]
      end
      if (last = entries.last) && last[1] == old_state
        checked = [last[0]['lastChecked'], date_key(old_current[LAST_CHECKED])].compact.max
        last[0]['lastChecked'] = checked if checked
      end
    end
    if (last = entries.last)
      last_date = last[0]['parseDate']
      raise ParseError, "#{org}: #{path} already has a later scrape (#{last_date})" if meta['parseDate'] < last_date
      if meta['parseDate'] == last_date
        entries.pop # Same-day correction replaces that day's scrape
      elsif last[0]['lastChecked'].to_s >= meta['parseDate']
        last[0]['lastChecked'] = day_before(meta['parseDate'])
      end
    end
    entries << [meta, state]
    write_history(path, build_history(org, entries))
  end

  # Write an org's current sponsor data, and its history when the list changed
  # Unchanged lists keep their parseDate and only update lastChecked.
  # @param model current sponsorship model (for source and modelDate), or nil
  # @param history_dir directory of history files, or nil for no history
  # @return :new, :changed, or :unchanged
  # @raise ParseError on a suspicious drop (unless force) or a history conflict
  def record_sponsors(org, path, sponsors, model: nil, history_dir: nil, force: false, today: Date.today)
    old = load_existing(path)
    forced = guard_drift!(org, path, sponsors, force: force)
    static = model && source_type(model) == 'static'
    parse_date = date_key(sponsors[PARSE_DATE]) || date_key(today)
    checked = static ? parse_date : date_key(today)
    state = level_lists(sponsors)
    if old && level_lists(old) == state
      updated = old.merge(LAST_CHECKED => [date_key(old[LAST_CHECKED]), checked].compact.max)
      write_sponsors(path, updated) unless updated == old
      return :unchanged
    end
    if history_dir
      meta = { 'parseDate' => parse_date, 'lastChecked' => checked, 'source' => static ? 'manual' : 'scrape',
               'modelDate' => model && date_key(model[EFFECTIVE_DATE]), 'forced' => (true if forced) }.compact
      append_history(history_path(history_dir, org), org, old, meta, state)
    end
    write_sponsors(path, sponsors.merge(PARSE_DATE => parse_date, LAST_CHECKED => checked))
    return old ? :changed : :new
  end

  # Turn one past version of an org's data into a sponsor list, or nil if unusable
  # Error entries are dropped and current normalization is applied.  Empty lists are
  # skipped, as are lists where two levels hold exactly the same sponsors (2 or more),
  # which comes from a level's selector copied from another level, not from a real page.
  # @return [parseDate, {level => sponsors}] or nil
  def version_state(data)
    return nil unless data.is_a?(Hash)
    date = begin
      date_key(data[PARSE_DATE])
    rescue ParseError
      nil
    end
    return nil unless date
    lists = data.select { |_lvl, ary| ary.is_a?(Array) }
                .transform_values { |ary| ary.reject { |s| s.to_s.start_with?('ERROR') } }
    state = level_lists(renormalize(lists))
    return nil if state.empty?
    return nil if state.values.select { |ary| ary.size >= 2 }.combination(2).any? { |a, b| a == b }
    return [date, state]
  end

  # @return array of [commit, file contents] for every git version of a file, oldest first
  def git_versions(path)
    log_out, status = Open3.capture2('git', 'log', '--format=%H', '--', path)
    raise ParseError, "git log #{path} failed; run from the repository root" unless status.success?
    log_out.split.reverse.filter_map do |commit|
      content, ok = Open3.capture2('git', 'show', "#{commit}:#{path}")
      [commit, content] if ok.success?
    end
  end

  # Build an org's history from every committed version of its data
  # Uses _data/allsponsorships.json versions (early 2024) and _data/sponsorships/<org>.json
  # versions, plus the working copy.  Versions with the same parseDate keep the newest;
  # consecutive identical lists extend the earlier scrape's lastChecked.
  # @param model sponsorship model (for modelDate), or nil
  # @return history hash, or nil if no usable versions
  def backfill_history(org, outdir: DEFAULT_OUTDIR, model: nil)
    by_date = {}
    add = lambda do |data|
      date, state = version_state(data)
      by_date[date] = state if date
    end
    @all_sponsorships_versions ||= git_versions(ALL_SPONSORSHIPS_FILE).map { |_c, content| JSON.parse(content) rescue {} }
    @all_sponsorships_versions.each { |all| add.call(all[org]) if all.is_a?(Hash) }
    path = File.join(outdir, "#{org}.json")
    git_versions(path).each { |_commit, content| add.call(JSON.parse(content)) rescue nil }
    add.call(load_existing(path))
    entries = []
    by_date.sort.each do |date, state|
      if entries.last && entries.last[1] == state
        entries.last[0]['lastChecked'] = date
        next
      end
      meta = { 'parseDate' => date, 'lastChecked' => date, 'source' => 'git' }
      meta['modelDate'] = date_key(model_at(model, date)[EFFECTIVE_DATE]) if model
      entries << [meta.compact, state]
    end
    return entries.empty? ? nil : build_history(org, entries)
  end

  # Re-apply normalization to every history file in a directory
  # @return array of paths changed
  def renormalize_history_files(history_dir, orgs = nil)
    orgs ||= Dir.glob(File.join(history_dir, '*.json')).map { |f| File.basename(f, '.json') }.sort
    orgs.filter_map do |org|
      path = history_path(history_dir, org)
      hist = load_history(path)
      next unless hist
      entries = history_states(hist).map { |meta, state| [meta, level_lists(renormalize(state))] }
      updated = build_history(org, entries)
      next if history_json(updated) == history_json(hist)
      write_history(path, updated)
      path
    end
  end

  # ## ### #### ##### ######
  # Output and command line

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
      opts.on('-c', '--check', 'Report stale or changed data vs a fresh parse; never writes. Exit 1 if any.') do
        options[:check] = true
      end
      opts.on('--max-age DAYS', Integer, "With --check: days before data is stale (default #{DEFAULT_MAX_AGE}).") do |days|
        options[:max_age] = days
      end
      opts.on('--offline', 'With --check: only check parseDate ages; do not fetch.') do
        options[:offline] = true
      end
      opts.on('--renormalize', 'Re-apply current host normalization to existing data files; no fetching.') do
        options[:renormalize] = true
      end
      opts.on('-f', '--force', 'Write even when sponsor counts drop suspiciously; with --backfill-git, replace history files.') do
        options[:force] = true
      end
      opts.on('--history DIR', "Sponsor history directory (default #{DEFAULT_HISTORY_DIR}; off with --out or --in unless given).") do |dir|
        options[:history] = dir
      end
      opts.on('--no-history', 'Do not write sponsor history files.') do
        options[:no_history] = true
      end
      opts.on('--backfill-git', 'Create history files from committed versions of the data; no fetching.') do
        options[:backfill] = true
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

  # Re-apply normalization to every (or one) existing org data file
  # Report files like sponsor-counts.json (with a dash) are skipped
  # @return array of paths changed
  def renormalize_files(outdir, orgs = nil)
    orgs ||= Dir.glob(File.join(outdir, '*.json')).map { |f| File.basename(f, '.json') }.reject { |o| o.include?('-') }.sort
    orgs.filter_map do |org|
      path = File.join(outdir, "#{org}.json")
      old = load_existing(path)
      next unless old
      updated = renormalize(old)
      next if updated == old
      write_sponsors(path, updated)
      path
    end
  end

  # Which history directory a run writes to, if any
  # History is on by default only for normal runs writing the repository's own data.
  # @return directory or nil
  def history_dir_for(options)
    return nil if options[:no_history]
    return options[:history] if options[:history]
    return nil if options[:out] || options[:infile]
    return DEFAULT_HISTORY_DIR
  end

  # Create history files for orgs that do not have one, from git versions of their data
  # @return array of paths written
  def backfill_files(outdir, history_dir, orgs, force: false)
    orgs.filter_map do |org|
      path = history_path(history_dir, org)
      if File.exist?(path) && !force
        warn_msg("backfill: #{path} exists; skipping (use --force to replace)")
        next
      end
      model = begin
        get_sponsorship_file(org)
      rescue ParseError
        nil
      end
      hist = backfill_history(org, outdir: outdir, model: model)
      next log("backfill: no usable versions for #{org}") unless hist
      write_history(path, hist)
      path
    end
  end

  # ### #### ##### ######
  # Main method for command line use
  # @return exit code
  def main(argv = ARGV)
    options = parse_commandline(argv)
    self.verbose = options.fetch(:verbose, false)
    failures = {}
    orgid = options[:orgid]
    if orgid && !ORG_ID_PATTERN.match?(orgid)
      raise ParseError, "--one: invalid org id #{orgid}"
    end
    if options[:check]
      orgs = orgid ? [orgid] : all_org_ids
      max_age = options.fetch(:max_age, DEFAULT_MAX_AGE)
      results = check_sponsorships(orgs, outdir: options.fetch(:out, DEFAULT_OUTDIR), max_age: max_age, offline: options[:offline])
      return report_check(results, max_age)
    elsif options[:renormalize]
      changed = renormalize_files(options.fetch(:out, DEFAULT_OUTDIR), orgid && [orgid])
      history_dir = history_dir_for(options.merge(infile: nil))
      changed += renormalize_history_files(history_dir, orgid && [orgid]) if history_dir && Dir.exist?(history_dir)
      changed.each { |path| log("Renormalized #{path}") }
      puts "Renormalized #{changed.size} file(s)"
    elsif options[:backfill]
      outdir = options.fetch(:out, DEFAULT_OUTDIR)
      history_dir = options[:history] || DEFAULT_HISTORY_DIR
      written = backfill_files(outdir, history_dir, orgid ? [orgid] : all_org_ids, force: options[:force])
      puts "Backfilled #{written.size} history file(s) in #{history_dir}"
    elsif (mapid = options[:mapid])
      raise ParseError, "--map: invalid id #{mapid}" unless ORG_ID_PATTERN.match?(mapid)
      sponsor_file = File.join(DEFAULT_OUTDIR, "#{mapid}.json")
      links = JSON.parse(read_local(sponsor_file))
      write_sponsors(sponsor_file, cleanup_with_map(links, File.join('_data', "#{mapid}_map.json")))
    elsif orgid
      sponsorship = model_at(get_sponsorship_file(orgid))
      parsed = process_sponsorship(orgid, sponsorship, options[:infile])
      path = output_path(options[:out], orgid)
      result = record_sponsors(orgid, path, parsed, model: sponsorship, history_dir: history_dir_for(options), force: options[:force])
      log("#{orgid}: #{result}")
    else
      outdir = options.fetch(:out, DEFAULT_OUTDIR)
      raise ParseError, "--out #{outdir} must be an existing directory" unless File.directory?(outdir)
      history_dir = history_dir_for(options)
      process_all_sponsorships(failures).each do |org, sponsors|
        path = File.join(outdir, "#{org}.json")
        result = record_sponsors(org, path, sponsors, model: model_at(get_sponsorship_file(org)),
                                 history_dir: history_dir, force: options[:force])
        log("#{org}: #{result}")
      rescue ParseError => e
        failures[org] = e.message
      end
    end
    return report_failures(failures)
  rescue ParseError, JSON::ParserError => e
    warn "ERROR: #{e.message}"
    return 1
  end

  exit(main) if __FILE__ == $PROGRAM_NAME
end
