#!/usr/bin/env ruby
module SponsorUtils
  DESCRIPTION = <<-HEREDOC
  SponsorUtils: good-enough scrapers and detectors of FOSS sponsors.
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
  # TODO: sponsor levels as an enum for consistency?
  # NOTE Sponsor names are in a separate table

  # @return a good enough normalized url
  # FIXME .strip.downcase.sub('www.','').sub('http://', 'https://') # Some cheap normalization
  def normalize_href(base, href)
    return nil if href.nil?
    return nil if /\/?#\z/.match(href) # Skip bare fragments
    url = URI(href)
    return url.absolute? ? url.to_s : URI(base).merge(href).to_s
  end

  ASF_SPONSOR_CSS = { # Listing as of 2023: ul id="platinum" ul li a, gold, silver, bronze; targetedplatinum, etc.
    'first' => '#platinum li a',
    'second' => '#gold li a',
    'third' => '#silver li a',
    'fourth' => '#bronze li a',
    'firstinkind' => '#targetedplatinum li a',
    'secondinkind' => '#targetedgold li a',
    'thirdinkind' => '#targetedsilver li a',
    'fourthinkind' => '#targetedbronze li a'
  }
  NUMFOCUS_SPONSOR_CSS = {
    'first' => '.et_pb_section_1 .et_pb_row_1 div > a',
    'second' => '.et_pb_section_1 .et_pb_row_4 div > a',
    'third' => '.et_pb_section_1 .et_pb_row_7 div > a',
    'community' => '.et_pb_section_1 .et_pb_row_10 div > a',
    'startuppartners' => '.et_pb_section_1 .et_pb_row_13 a',
    'grants' => '.et_pb_section_2 a'
  }
  OSGEO_SPONSOR_CSS = {
    'first' => '.Diamond-sponsors a',
    'second' => '.Platinum-sponsors a',
    'third' => '.Gold-sponsors  a',
    'fourth' => '.Silver-sponsors  a',
    'fifth' => '.Bronze-sponsors a'
  }
  DRUPAL_SPONSOR_CSS = {
    'first' => '.sponsors--signature a',
    'second' => '.view-display-id-attachment_6 a',
    'third' => '.view-display-id-attachment_3 a',
    'fourth' => '.view-display-id-attachment_1 a',
    'community' => '.view-display-id-attachment_9 a'
  }
  DRUPAL_SPONSOR_PAGE = '.org-link a'

  # Scrape sponsor listing defined by css selectors
  # @param io input stream of html to parse
  # @return hash of sponsors by approximate map-defined levels
  def scrape_bycss(io, baseurl, selectors)
    sponsors = {}
    doc = Nokogiri::HTML5(io)
    body = doc.xpath('/html/body')
    selectors.each do | key, selector |
      nodelist = body.css(selector)
      sponsors[key] = []
      nodelist.each do | node |
        sponsors[key] << node['href']
      end
    end
    return sponsors
  end
end

# ### #### ##### ######
# Main method for command line use
if __FILE__ == $PROGRAM_NAME
  filename = '../../../sponsors-drupal.html'
  baseurl = ''
  io = File.open(filename)
  sponsors = SponsorUtils.scrape_bycss(io, baseurl, SponsorUtils::DRUPAL_SPONSOR_CSS)
  puts JSON.pretty_generate(sponsors)
end
