#!/usr/bin/env ruby
module SponsorUtils
  DESCRIPTION = <<-HEREDOC
  SponsorUtils: good-enough scrapers and detectors of FOSS sponsors.
    Default to run from project root directory; will find and
    parse all available foundation/sponsorship mappings.
  HEREDOC
  module_function
  require 'csv'
  require 'yaml'
  require 'json'
  require 'open-uri'
  require 'nokogiri'
  require 'date'
  require 'optparse'
  require_relative 'foundation_reporter'

  attr_accessor :verbose
  def verbose(s)
    puts s if @verbose
  end
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
  DEFAULT_OUTDIR = '_data/sponsorships'
  ERROR_REPORT = 'error'
  PARSE_DATE = 'parseDate'

  # Return a normalized domain name for mapping to a single sponsor org
  # HACK note several special casees mapping down to single org
  # @return a good enough normalized hostname
  def normalize_href(href)
    begin
    return URI(href.strip.downcase.sub('www.', '')
      .sub('opensource.google', 'google.com')
      .sub('techatbloomberg.com', 'bloomberg.com')
      .sub('opensource.twosigma.com', 'twosigma.com')
      .sub('opensource.salesforce.com', 'salesforce.com')
      # TODO: consider removing ^cloud. from: google baidu tencent
      # TODO: consider removing ^aws. from amazon ^azure. from microsoft
      # TODO: consider removing ^group. from mercedes-benz
      # TODO: consider removing ^en. from various urls
      ).authority
    rescue StandardError => e
      return href
    end
  end

  # Scrape html sponsor listing defined by css selectors
  # @param io input stream of html to parse
  # @param sponsor level map of organization
  # @return hash of sponsors by approximate map-defined levels
  def scrape_bycss(io, sponsorship)
    sponsors = {}
    normalize = sponsorship.fetch('normalize', nil)
    cssmap = sponsorship['levels']
    doc = Nokogiri::HTML5(io)
    body = doc.xpath('/html/body')
    cssmap.each do | lvl, lvldata |
      sponsors[lvl] = []
      begin
        nodelist = body.css(lvldata['selector'])
        attr = lvldata['attr']
        nodelist.each do | node |
          if 'href'.eql?(attr) && normalize
            sponsors[lvl] << normalize_href(node[attr])
          else
            sponsors[lvl] << node[attr]
          end
        end
      rescue StandardError => e
        sponsors[lvl] << "ERROR: scrape_bycss(...#{lvl}, ... #{lvldata['selector']})" # Leaving Nokigiri error may cause GH Pages build issues
      end
    end
    return sponsors
  end

  # Parse a CNCF style landscape.yml for a sponsor list
  # @param io input stream of YAML to parse
  # @param sponsor level map of organization
  # @return hash of sponsors by approximate map-defined levels
  def parse_landscape(io, sponsorship)
    category = sponsorship['landscape']
    landscape = YAML.safe_load(io, aliases: true)
    landscape = landscape['landscape'] # will be array
    landscape = landscape.select{ | h | category.eql?(h.fetch('name', '')) }
    groups = landscape.first.fetch('subcategories', nil)
    sponsors = {}
    if groups
      groups.each do | group |
        levelname = group['name']
        level = ''
        sponsorship['levels'].each do | lvl, h |
          if levelname.eql?(h.fetch('name', ''))
            level = lvl
            break
          end
        end
        sponsors[level] = []
        group['items'].each do | sponsor |
          sponsors[level] << normalize_href(sponsor.fetch('homepage_url', sponsor['name']))
        end
      end
    else
      sponsors[ERROR_REPORT] = "ERROR: parse_landscape(... #{category}) not found"
    end
    return sponsors
  end

  # Cleanup sponsor lists that are IDs not domains
  # @param sponsors hash of detected sponsor ids
  # @param filename of json mapping to read, from 'sponsormap'
  # @return sponsors hash normalized to domain names
  def cleanup_with_map(links, mapname)
    sponsors = {}
    begin
      map = JSON.parse(File.read(mapname))
    rescue StandardError => e
      sponsors[ERROR_REPORT] = "ERROR: cleanup_with_map(...#{mapname}): #{e.message}"
      return links ## FIXME, figure out right way to handle this rare error
    end

    links.each do | level, ary |
      next unless ary.is_a?(Array) # Skip dates, errors, etc
      sponsors[level] = []
      ary.each do | itm |
        newitm = map.fetch(itm, nil)
        newitm ? sponsors[level] << newitm : sponsors[level] << normalize_href(itm)
      end
    end
    return sponsors
  end

  # Parse separate per-sponsor pages used by some orgs
  # @param sponsors hash of previously detected sponsor links
  # @param sponsorship definition hash with 'sponsorroot', 'sponsorselector'
  # @return sponsors hash normalized to domain names
  def parse_subpages(existing_sponsors, sponsorship)
    sponsors = {}
    rooturl = sponsorship['sponsorroot']
    selector = sponsorship['sponsorselector']
    existing_sponsors.each do | level, ary |
      next unless ary.is_a?(Array) # Skip dates, errors, etc
      sponsors[level] = []
      ary.each do | itm |
        # Either store a normalized URL if present, or go parse the subpage
        if itm.downcase.start_with?('http')
          sponsors[level] << itm
        else
          begin
            doc = Nokogiri::HTML5(URI.parse("#{rooturl}#{itm}").open.read)
            node = doc.at_css(selector)
            if node
              sponsors[level] << normalize_href(node['href'])
            else
              sponsors[level] << itm
            end
          rescue StandardError => e
            sponsors[level] << "ERROR: parse_subpages(...#{itm}): #{e.message}\n\n#{e.backtrace.join("\n\t")}"
          end
        end
      end
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
  def parse_sponsorship(org, sponsorship, cachefile = nil)
    io = nil
    sponsors = {}
    sponsorurl = sponsorship['sponsorurl']
    begin
      if cachefile
        io = File.open(cachefile)
      else
        io = URI.open(sponsorurl).read
      end
    rescue StandardError => e
      sponsors[ERROR_REPORT] = "ERROR: parse_sponsorship(#{cachefile ? cachefile : sponsorurl}): #{e.message}\n\n#{e.backtrace.join("\n\t")}"
      return sponsors
    end
    # Parse a landscape.yml, or scrape a webpage by css
    if sponsorship.fetch('landscape', nil)
      sponsors = SponsorUtils.parse_landscape(io, sponsorship)
    else
      sponsors = SponsorUtils.scrape_bycss(io, sponsorship)
    end
    # Custom post-processing for various orgs
    subpage = sponsorship.fetch('sponsorselector', nil)
    if subpage
      sponsors = SponsorUtils.parse_subpages(sponsors, sponsorship)
    end
    mapping = sponsorship.fetch('sponsormap', nil)
    if mapping
      sponsors = SponsorUtils.cleanup_with_map(sponsors, mapping)
    end
    return sponsors
  end

  # Copy over a static map of sponsors for an org
  # @param org id of org being parsed
  # @param sponsorship parsed _sponsorship hash with static sponsor arys
  # @return processed hash of sponsors
  def mapped_sponsorship(org, sponsorship)
    sponsors = {}
    sponsorship['levels'].each do | lvl, hash |
      sponsors[lvl] = hash['sponsors']
    end
    return sponsors
  end

  # Process one sponsorship mapping
  # @param org id of org being processed
  # @param sponsorship parsed _sponsorship hash
  # @param cachefile optional filepath to local html to parse
  # @return processed hash of sponsors
  def process_sponsorship(org, sponsorship, cachefile = nil)
    sponsors = {}
    staticmap = sponsorship.fetch('staticmap', nil)
    verbose("process_sponsorship(#{org}...) #{staticmap ? 'static map' : 'parsing url'}")
    if staticmap
      sponsors = mapped_sponsorship(org, sponsorship)
      sponsors[PARSE_DATE] = staticmap
    else
      sponsors = parse_sponsorship(org, sponsorship, cachefile)
      sponsors[PARSE_DATE] = DateTime.now.strftime('%Y%m%d')
    end
    return sponsors
  end

  # Process a list of sponsorship maps
  # TODO future use: allow historical sponsorship maps via get_current_sponsorship
  # @param sponsorships array org => of _sponsorship hashes
  # @return hash of orgs = {sponsors...}
  def process_sponsorships(sponsorships)
    all_sponsors = {}
    sponsorships.each do | org, sponsorship |
      all_sponsors[org] = process_sponsorship(org, get_current_sponsorship(sponsorship))
    end
    return all_sponsors
  end

  # Convenience method; assumes run from project root
  def process_all_sponsorships()
    foundations = FoundationReporter.get_yamldataset(FoundationReporter::DATA_DIRS['foundations'])
    all_sponsor_models = {}
    foundations.each do | org, foundation |
      sponsor_models = foundation.fetch('sponsorships', nil)
      if sponsor_models && sponsor_models.is_a?(String)
        all_sponsor_models[org] = get_sponsorship_file(sponsor_models)
      elsif sponsor_models && sponsor_models.is_a?(Array)
        sponsor_models.each do | sponsormap | # Allows multiple sponsorship maps per org; see lf.md
          all_sponsor_models[sponsormap] = get_sponsorship_file(sponsormap)
        end
      end
    end
    all_sponsors = process_sponsorships(all_sponsor_models)
    return all_sponsors
  end

  # Convenience method to get a sponsorship file by org id
  def get_sponsorship_file(org)
    return YAML.safe_load(File.read("_sponsorships/#{org}.md"), aliases: true)
  end

  # ## ### #### ##### ######
  # Check commandline options
  def parse_commandline
    options = {}
    OptionParser.new do |opts|
      opts.on('-h', '--help') { puts "#{DESCRIPTION}\n#{opts}"; exit }
      opts.on('-oOUTFILE', '--out OUTFILE', 'Output dir or filename for operation.') do |out|
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
      opts.on("-v", "--[no-]verbose", "Verbose output to stdout.") do |v|
        options[:verbose] = v
        @verbose = v
      end
      begin
        opts.parse!
      rescue OptionParser::ParseError => e
        $stderr.puts e
        $stderr.puts opts
        exit 1
      end
    end
    return options
  end

  # ### #### ##### ######
  # Main method for command line use
  if __FILE__ == $PROGRAM_NAME
    options = parse_commandline
    orgid = options.fetch(:orgid, nil)
    mapid = options.fetch(:mapid, nil)
    infile = options.fetch(:infile, nil)
    parsed = {}
    if mapid
      sponsor_file = File.join('_data/sponsorships', "#{mapid}.json")
      links = JSON.parse(File.read(sponsor_file))
      mapname = File.join('_data', "#{mapid}_map.json")
      newfile = cleanup_with_map(links, mapname)
      File.open(sponsor_file, "w") do |f|
        f.write(JSON.pretty_generate(newfile))
      end
      exit 0
    elsif orgid
      options[:outfile] ||= File.join(DEFAULT_OUTDIR, "#{orgid}.json")
      sponsorship = get_current_sponsorship(get_sponsorship_file(orgid))
      if infile
        # Parse a local file instead of the normal URL
        parsed = process_sponsorship(orgid, sponsorship, cachefile = infile)
      else
        parsed = process_sponsorship(orgid, sponsorship)
      end
      File.open(options[:outfile], "w") do |f|
        f.write(JSON.pretty_generate(parsed))
      end
      exit 0
    else
      options[:outfile] ||= DEFAULT_OUTDIR
      parsed = process_all_sponsorships()
    end
    parsed.each do | org, sponsorship |
      next if ERROR_REPORT.eql?(org) # FIXME use a better way of passing errors overall
      next if PARSE_DATE.eql?(org)
      File.open(File.join(options[:outfile], "#{org}.json"), "w") do |f|
        f.write(JSON.pretty_generate(sponsorship))
      end
    end
  end
end
