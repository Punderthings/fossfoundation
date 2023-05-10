#!/usr/bin/env ruby
DESCRIPTION = <<HEREDOC
Various web scrapers and utilities for importing 'good-enough' data from 
multi-project foundation project listing pages.
HEREDOC
require 'csv'
require 'yaml'
require 'json'
require 'open-uri'

HEADERS = %w( identifier commonName description website foundingDate parentOrganization )

# Transform ASF's project listing into simple csv structure
# This method directly maps the ASF's committee-info structure into our simplified csv
def scrape_asf_projects(outfile)
  asf = JSON.load_file(URI.open('https://whimsy.apache.org/public/committee-info.json'))
  projects = asf['committees'] # asf['last_updated'] is when the ASF structure was last created
  lines = 0
  CSV.open(outfile, "w", headers: HEADERS, write_headers: true) do |csv|
    projects.each do |project, h|
      csv << [h['display_name'].downcase.gsub(/\s+/, ''), "Apache #{h['display_name']}", h['description'], h['site'], h['established'], 'asf']
      lines += 1
    end
  end
  return lines
end

### Command line use
# outfile = '_data/projects-asf.csv'
# puts "BEGIN #{__FILE__}.scrape_asf_projects(#{outfile})"
# lines = scrape_asf_projects(outfile)
# puts "END wrote #{lines} lines"
