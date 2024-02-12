#!/usr/bin/env ruby
DESCRIPTION = <<HEREDOC
Various web scrapers and utilities for importing 'good-enough' data from
multi-project foundation project listing pages.
HEREDOC
require 'csv'
require 'yaml'
require 'json'
require 'open-uri'
require 'nokogiri' # Voodoo: attempt to fix GH Pages workflow fails: https://github.com/Punderthings/fossfoundation/actions/runs/5013763951/jobs/8993067589
require 'uri'

# Common headers used for all foundation listings
HEADERS = %w( identifier commonName description website foundingDate parentOrganization )

# Transform ASF's project listing into simple csv structure
# This method directly maps the ASF's committee-info structure into our simplified csv
def scrape_asf_projects(outfile)
  asf = JSON.load_file(URI.open('https://whimsy.apache.org/public/committee-info.json'))
  projects = asf['committees'] # asf['last_updated'] is when the ASF structure was last created
  lines = 0
  CSV.open(outfile, "w", headers: HEADERS, write_headers: true) do |csv|
    projects.each do |key, h|
      csv << [key.downcase.gsub(/\W+/, ''), "Apache #{h['display_name']}", h['description'], h['site'], h['established'], 'asf']
      lines += 1
    end
  end
  return lines
end

# Transform Software Freedom Conservancy project listing into simple csv structure
def scrape_sfc_projects(outfile)
  sfc_url = 'https://sfconservancy.org/projects/current/'
  doc = Nokogiri::HTML(URI.open(sfc_url))
  element = doc.css('#mainContent h2')
  projects = {}
  element.each do |e|
    p e.text
    projects[e.text.downcase.gsub(/\W+/, '')] = {
      'commonName' => e.text.strip,
      'website' => sfc_project_url(e),
      'description' => sfc_description(e)
    }
  end
  lines = 0
  CSV.open(outfile, "w", headers: HEADERS, write_headers: true) do |csv|
    projects.each do |key, h|
      csv << [key, h['commonName'], h['description'], h['website'], h['foundingDate'], 'sfc']
      lines += 1
    end
  end
  return lines
end

def sfc_project_url(doc)
  url = doc.css('a')[0]['href']
  if url.start_with?('http')
    return url
  else
    return 'https://sfconservancy.org' + url
  end
end

def sfc_description(doc)
  e = doc.next_element
  if e.name == 'p'
    return e.text.strip
  else
    e = e.next_element
    if e.name == 'p'
      return e.text.strip
    else
      e.next_element.text.strip
    end
  end
end

# Transform SPI, Inc. project listing into simple csv structure
# def scrape_spi_projects(outfile)
#   spi_url = 'https://www.spi-inc.org/projects/'
#   doc = Nokogiri::HTML(URI.open(spi_url))
#   table = doc.at('.projects')
#   cells = table.search('td')
#   projects = {}
#   ctr = 0
#   cells.each do |cell|
#     a = cell.search('a')
#     project_doc = Nokogiri::HTML(URI.open(spi_url + a[0]['href']))
#     projects[cell.text.downcase.gsub(/\W+/, '')] = {
#       'commonName' => cell.text.strip,
#       'website' => spi_website(project_doc, spi_url + a[0]['href']),
#       'description' => project_doc.css('div#content p').text.strip,
#     }
#   end
#   lines = 0
#   CSV.open(outfile, "w", headers: HEADERS, write_headers: true) do |csv|
#     projects.each do |key, h|
#       csv << [key, h['commonName'], h['description'], h['website'], h['foundingDate'], 'spi']
#       lines += 1
#     end
#   end
#   return lines
# end

# def spi_website(doc, fallback_url)
#   a = doc.css('div#content p a')
#   if a.length > 0
#     return a[0]['href']
#   else
#     return fallback_url
#   end
# def scrape_numfocus_projects(outfile)
#   numfocus_url = 'https://numfocus.org/sponsored-projects'
#   doc = Nokogiri::HTML(URI.open(numfocus_url))
#   results = doc.css('.search-filter-results .search-result-item h2 a')
#   projects = {}
#   results.each do |result|
#     puts "#{result.text} #{result['href']}"
#     project_doc = Nokogiri::HTML(URI.open(result['href']))
#     projects[result.text.downcase.gsub(/\W+/, '')] = {
#       'commonName' => result.text,
#       'website' => numfocus_website(project_doc, result['href']),
#       'description' => project_doc.css('.et_pb_header_content_wrapper p:first').text,
#       'foundingDate' => project_doc.at('.et_pb_fullwidth_header_subhead').text.split('since ')[-1]
#     }
#   end
#   lines = 0
#   CSV.open(outfile, "w", headers: HEADERS, write_headers: true) do |csv|
#     projects.each do |key, h|
#       csv << [key, h['commonName'], h['description'], h['website'], h['foundingDate'], 'numfocus']
#       lines += 1
#     end
#   end
#   return lines
# end

# def numfocus_website(project_doc, fallback_url)
#   project_doc.at('a:contains("Website")')['href']
# rescue
#   fallback_url
# end

### Command line use
# outfile = '_data/projects-asf.csv'
# puts "BEGIN #{__FILE__}.scrape_asf_projects(#{outfile})"
# lines = scrape_asf_projects(outfile)
# puts "END wrote #{lines} lines"

# outfile = '_data/projects-spi.csv'
# puts "BEGIN #{__FILE__}.scrape_spi_projects(#{outfile})"
# lines = scrape_spi_projects(outfile)
# puts "END wrote #{lines} lines"

# outfile = '_data/projects-numfocus.csv'
# puts "BEGIN #{__FILE__}.scrape_numfocus_projects(#{outfile})"
# lines = scrape_numfocus_projects(outfile)
# puts "END wrote #{lines} lines"

outfile = '_data/projects-sfc.csv'
puts "BEGIN #{__FILE__}.scrape_sfc_projects(#{outfile})"
lines = scrape_sfc_projects(outfile)
puts "END wrote #{lines} lines"
