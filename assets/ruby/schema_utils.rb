#!/usr/bin/env ruby
DESCRIPTION = <<HEREDOC
Transformation utilities for csv data into json/yaml/md data.
- Transform spreadsheet data rows into individual .md files with frontmatter.
Each row becomes a name.md file, where each column value becomes a header:value pair of YAML frontmatter.
HEREDOC
require 'csv'
require 'yaml'
require 'json'

# Transform original spreadsheet with all columns into Jekyll-readable frontmatter files
# Note: currently requires manual check/update of outputs
# TODO: ensure stable output format for field ordering, line wrapping
# BUG: .md files output must have a closing --- document end marker added
def csv2jekyll(infile, outdir, outext)
  lines = 0
  CSV.foreach(File.open(infile), {:headers => true}) do |row|
    lines += 1
    File.open(File.join(outdir, "#{row['identifier']}#{outext}"), 'w') do |file|
      file.write(YAML.dump(row.to_h))
    end
    File.open(File.join(outdir, "#{row['identifier']}.json"), 'w') do |file|
      file.write(JSON.dump(row.to_h))
    end
  end
  return lines
end

# Transform csv of field descriptions to JSON Schema
def csv2jsonschema(infile, outfile)
  lines = 0
  props = {}
  jsonschema =  {
    '$schema': 'http://json-schema.org/draft-06/schema#', 
    '$id': 'https://fossfoundation.info/foundations/asf.json',
    'type': 'object',
    'title': 'FOSS Foundation Schema',
    "required": [
      "identifier",
      "name",
      "website",
      "description"
    ],
    'properties': props
  }
  CSV.foreach(File.open(infile), {:headers => true}) do |row|
    lines += 1
    props[row['fieldName']] = {
      'title': row['title'],
      'description': row['description'],
      'type': row['type']
    }
    props[row['fieldName']]['format'] = row['format'] unless row['format'].nil?
  end
  File.open(File.join(outfile), 'w') do |file|
    file.write(JSON.pretty_generate(jsonschema)) # TODO: ensure stable output format for field ordering
  end
return lines
end

# Transform JSON Schema into Jekyll Liquid templates
# NOTE: only creates partial template; manual tweaking necessary
def schema2liquid(infile, linesep)
  liquid = ''
  schema = JSON.parse(File.read(infile))
  properties = schema['properties']
  properties.each do |fieldName, hash|
    liquid << "{% if page.#{fieldName} %}"
    liquid << "<abbr title=\"#{hash['description']}\">#{hash['title']}</abbr>: "
    if 'url'.eql?(hash.fetch('format', ''))
      liquid << "<a itemprop=\"#{fieldName}\" href=\"{{ page.#{fieldName} }}\">{{ page.#{fieldName} }}</a>"
    else
      liquid << "<span itemprop=\"#{fieldName}\">{{ page.#{fieldName} }}</span>"
    end
    liquid << linesep if linesep
    liquid << "{% endif %}\n"
  end
  return liquid
end

# puts "BEGIN #{__FILE__}.csv2jekyll(#{infile}, #{outdir}, #{outext})"
# lines = csv2jekyll(infile, outdir, outext)
# puts "END parsed csv rows: #{lines}"

# puts "BEGIN #{__FILE__}.csv2jsonschema(#{infile}, #{outfile})"
# lines = csv2jsonschema(infile, outfile)
# puts "END parsed csv rows: #{lines}"

infile = '_data/foundations-schema.json'
linesep = "<br/>"
puts "BEGIN #{__FILE__}.schema2liquid(#{infile}, #{linesep})"
lines = schema2liquid(infile, linesep)
File.write('foundation-liquid.html', lines)
