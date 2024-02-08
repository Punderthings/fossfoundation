#!/usr/bin/env ruby
module SponsorUtils
  DESCRIPTION = <<-HEREDOC
  SponsorUtils: good-enough scrapers and detectors of FOSS sponsors.
  Default to run from project root directory.
  HEREDOC
  module_function
  require 'csv'
  require 'yaml'
  require 'json'
  require 'open-uri'
  require 'nokogiri'

  # NOTE OWASP parsing css may be fragile; relies on nth-of-type
  # TODO: Eclipse dom parsing:
  #   div.eclipsefdn-members-list ... a with href and title that has sponsor name
  #   Member page: div.member-detail a

  # Map all sponsorships to common-ish levels
  # - Ordinals are cash sponsorships in order
  # - inkind is services donations (i.e. not just cash)
  # - community is widely used as a separate level
  # - grants covers any sort of government/institution grants
  SPONSOR_METALEVELS = %w[ first second third fourth fifth sixth seventh eighth community firstinkind secondinkind thirdinkind fourthinkind startuppartners grants ]

  # Return a normalized domain name for mapping to a single sponsor org
  # HACK note several special casees mapping down to single org
  # @return a good enough normalized hostname
  def normalize_href(href)
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
  end

  SELECTOR_OFFSET = 2 # TODO change to using per-org sponsor levels
  ATTR_OFFSET = 3
  ATTR_HREF = 'href'
  # Scrape html sponsor listing defined by css selectors
  # @param io input stream of html to parse
  # @param sponsor level map of organization
  # @return hash of sponsors by approximate map-defined levels
  def scrape_bycss(io, orgmap)
    sponsors = {}
    normalize = orgmap.fetch('normalize', nil)
    cssmap = orgmap['levels']
    doc = Nokogiri::HTML5(io)
    body = doc.xpath('/html/body')
    cssmap.each do | key, selectors |
      nodelist = body.css(selectors[SELECTOR_OFFSET])
      sponsors[key] = []
      attr = selectors[ATTR_OFFSET]
      nodelist.each do | node |
        if ATTR_HREF.eql?(attr) && normalize
          sponsors[key] << normalize_href(node[attr])
        else
          sponsors[key] << node[attr]
        end
      end
    end
    return sponsors
  end

  # Read a CNCF style landscape for a sponsor list
  # @param io input stream of YAML to parse
  # @param sponsor level map of organization
  # @return hash of sponsors by approximate map-defined levels
  def parse_landscape(io, orgmap)
    landscape = YAML.safe_load(io, aliases: true)
    landscape = landscape['landscape'] # will be array
    category = orgmap['selector']
    landscape = landscape.select{ | h |  category.eql?(h.fetch('name', ''))}
    groups = landscape.first.fetch('subcategories', nil)
    sponsors = {}
    if groups
      groups.each do | group |
        levelname = group['name']
        level = ''
        orgmap['levels'].each do | lvl, h |
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
      sponsors['error'] = "ERROR: parse_landscape(... #{category}) not found"
    end
    return sponsors
  end

  # Cleanup sponsor lists that are IDs not domains
  # @param sponsors hash of detected sponsor ids
  # @param filename of json mapping to read
  # @return sponsors hash normalized to domain names
  def cleanup_with_map(links, mapname)
    sponsors = {}
    map = JSON.parse(File.read(mapname))
    links.each do | level, ary |
      sponsors[level] = []
      ary.each do | itm |
        sponsors[level] << map.fetch(itm, itm)
      end
    end
    return sponsors
  end

  DRUPAL_SPONSOR_CSS = '.org-link a' # Sponsor is kept on a separate page
  DRUPAL_SPONSOR_URL = 'https://www.drupal.org'

  # Cleanup drupal sponsor list, since they use separate files
  # @param sponsors hash of detected sponsor links
  # @return sponsors hash normalized to domain names
  def cleanup_drupal(links)
    sponsors = {}
    links.each do | level, ary |
      sponsors[level] = []
      ary.each do | itm |
        begin
          doc = Nokogiri::HTML5(URI.open("#{DRUPAL_SPONSOR_URL}#{itm}").read)
          node = doc.at_css(DRUPAL_SPONSOR_CSS)
          if node
            sponsors[level] << normalize_href(node['href'])
          else
            sponsors[level] << itm
          end
        rescue StandardError => e
          puts "ERROR: cleanup_drupal(...#{itm}): #{e.message}\n\n#{e.backtrace.join("\n\t")}"
          sponsors[level] << itm # HACK: leave as-is, will be obvious to reader
        end
      end
    end
    return sponsors
  end

  # Rough count of number of times different urls appear at levels
  # @param sponsors hash returned from scrape_bycss or cleanup
  # @return hash of counts of how often domain names appear
  def report_counts(sponsors)
    counts = {}
    SPONSOR_METALEVELS.each do | lvl |
      counts[lvl] = Hash.new(0)
    end
    counts['all'] = Hash.new(0)
    sponsors.each do | org, sponsorhash |
      sponsorhash.each do | level, ary |
        ary.each do | url |
          counts['all'][url] += 1
          counts[level][url] += 1
        end
      end
    end
    counts['all'] = Hash[counts['all'].sort_by { |k, v| -v }]
    return counts
  end

  # ### #### ##### ######
  # Main method for command line use
  if __FILE__ == $PROGRAM_NAME
    # TODO: default dir? Command line params? Load each sponsor level by org?
    orgmap = JSON.parse(File.read('_sponsors/cncf.json'))
    io = File.read('../../../../f/cncf-landscape/landscape.yml') # TODO parse url from the json
    orgmap = orgmap['20240101'] # HACK: select current one TODO allow different dates/versions
    sponsors = parse_landscape(io, orgmap)
    File.open('cncfout.json', "w") do |f|
      f.write(JSON.pretty_generate(sponsors))
    end
    puts "DEBUG - done testing parse_landscape"
    exit 1

    infile = 'sponsor_levels.json'
    outfile = 'sponsor_utils.json'
    io = nil
    sponsors = {}
    maps = JSON.parse(File.read(infile))
    maps.each do | org, map |
      map = map[0] # HACK: just use first map on list; by date for future use historical scans
      if true
        filename = "../../../sponsors-#{org}.html"
        baseurl = ''
        io = File.open(filename)
      else
        sponsorurl = map['sponsorurl']
        begin
          io = URI.open(sponsorurl).read
        rescue StandardError => e
          puts "ERROR: #{sponsorurl}: #{e.message}\n\n#{e.backtrace.join("\n\t")}"
          next
        end
      end
      sponsors[org] = SponsorUtils.scrape_bycss(io, map)
      case org
      when 'python'
        sponsors[org] = cleanup_with_map(sponsors[org], 'python_map.json')
      when 'drupal'
        sponsors[org] = cleanup_drupal(sponsors[org])
      when 'lf'
        sponsors[org] = cleanup_with_map(sponsors[org], 'lf_map.json')
      else
        # No-op
      end
    end
    File.open(outfile, "w") do |f|
      f.write(JSON.pretty_generate(sponsors))
    end
    counts = report_counts(sponsors)
    File.open('sponsor_metacount.json', "w") do |f|
      f.write(JSON.pretty_generate(counts))
    end
  end
end
