#!/usr/bin/env ruby
module SponsorUtils
  DESCRIPTION = <<-HEREDOC
  SponsorUtils: good-enough scrapers and detectors of FOSS sponsors.
  See also: scraping rules and sponsorship levels in sponsor_listing.json
  HEREDOC
  module_function
  require 'csv'
  require 'yaml'
  require 'json'
  require 'open-uri'
  require 'nokogiri'

  SPONSOR_MAP = { # Good enough map for common sponsors
    'Microsoft' => 'https://microsoft.com', # TODO determine exact normalization rules for sponsor links
    'Google' => 'https://google.com'
  }

  # Custom parsing data
  # Note OWASP parsing css may be fragile; relies on nth-of-type
  DRUPAL_SPONSOR_PAGE = '.org-link a' # Sponsor is kept on a separate page

  # Return a normalized domain name for mapping to a sponsor org
  # @return a good enough normalized url # FIXME
  def normalize_href(href)
    return URI(href.strip.downcase.sub('www.','')).authority
  end

  SELECTOR_OFFSET = 2
  ATTR_OFFSET = 3
  ATTR_HREF = 'href'
  # Scrape sponsor listing defined by css selectors
  # @param io input stream of html to parse
  # @param shortname of foundation map to parse
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

  PYTHON_MAP = { # Hack for Python, which merely stores IDs that uses ethicalads.io
    'google' => 'google.com' # etc. map ids to obvious sponsor domains
  }
  # Cleanup python sponsor list, since they use separate files
  # @param sponsors hash of detected sponsor links
  # @return sponsors hash normalized to domain names
  # def cleanup_python(links)
  #   sponsors = {}
  #   links.each do | level, ary |
  #     ary.each do | itm |
  # Un-PYTHON_MAP itm
  #     end
  #   end
  #   return sponsors
  # end

  # Rough count of number of times different urls appear at levels
  # @param sponsors hash returned from scrape_bycss or cleanup
  # @return hash of counts of how often domain names appear
  def report_counts(sponsors)
    # Setup data structure
    counts = {}
    counts['all'] = Hash.new(0)
    %w[ first second third fourth fifth sixth seventh eighth community firstinkind secondinkind thirdinkind fourthinkind startuppartners grants ].each do | lvl |
      counts[lvl] = Hash.new(0)
    end
    counts['all'] = Hash.new(0)
    # Iterate each sponsor and all levels data
    sponsors.each do | org, sponsorhash |
      sponsorhash.each do | level, ary |
        ary.each do | url |
          counts['all'][url] += 1
          counts[level][url] += 1
        end
      end
    end
    # Order for convenience
    counts['all'] = Hash[counts['all'].sort_by { |k, v| -v }]
    return counts
  end

  # ### #### ##### ######
  # Main method for command line use
  if __FILE__ == $PROGRAM_NAME
    infile = 'sponsor_levels.json'
    outfile = 'sponsor_utils.json'
    io = nil
    sponsors = {}
    maps = JSON.parse(File.read(infile))
    maps.each do | org, map |
      map = map[0] # HACK: just use first map on list; by date for future use historical scans
      if false
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
    end
    File.open(outfile, "w") do |f|
      f.write(JSON.pretty_generate(sponsors))
    end
    counts = report_counts(sponsors)
    puts JSON.pretty_generate(counts)
    File.open('sponsor_metacount.json', "w") do |f|
      f.write(JSON.pretty_generate(counts))
    end
  end
end
