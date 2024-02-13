#!/usr/bin/env ruby
DESCRIPTION = <<HEREDOC
Transformation utilities for csv data into json/yaml/md data.
- Transform spreadsheet data rows into individual .md files with frontmatter.
Each row becomes a name.md file, where each column value becomes a header:value pair of YAML frontmatter.
HEREDOC
require 'csv'
require 'yaml'
require 'json'
require 'optparse'

# Transform original spreadsheet with all columns into Jekyll-readable frontmatter files
# Note: currently requires manual check/update of outputs
# TODO: ensure stable output format for field ordering, line wrapping
# BUG: .md files output must have a closing --- document end marker added
def csv2jekyll(infile, outdir, outext)
  lines = 0
  puts "DEBUG #{infile}, #{outdir}, #{outext}"
  CSV.foreach(File.open(infile), :headers => true) do |row|
    lines += 1
    File.open(File.join(outdir, "#{row['identifier']}#{outext}"), 'w') do |file|
      file.write(YAML.dump(row.to_h))
    end
    # File.open(File.join(outdir, "#{row['identifier']}.json"), 'w') do |file|
    #   file.write(JSON.dump(row.to_h))
    # end
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

# HACK simplistic processing of hash/array schema objects (recursive)
# @param parentname string of this schema object that contains other objects
# @param schema hash to process and emit liquid for
# @param linesep to use if needed
# @return multiline string of liquid statements
def emit_schema_object(parentname, childname, schema, linesep)
  liquid = ''
  name_hack = parentname ? "#{parentname}.#{childname}" : childname
  properties = schema['properties']
  properties.each do |itmname, hash|
    if 'object'.eql?(hash['type'])
      liquid << "{% if page.#{name_hack}.#{childname}.#{itmname} %}\n"
      liquid << emit_schema_object(name_hack, itmname, hash, linesep)
      liquid << linesep if linesep
      liquid << "{% endif %}\n"
    else
      liquid << emit_schema_scalar(name_hack, itmname, hash, linesep)
    end
  end
  return liquid
end

# Simplistic processing of scalar schema objects
# @param fieldname string of this schema object
# @param schema hash to process and emit liquid for
# @param linesep to use if needed
# @return multiline string of liquid statements
def emit_schema_scalar(parentname, fieldname, schema, linesep)
  name_hack = parentname ? "#{parentname}.#{fieldname}" : fieldname
  liquid = "{% if page.#{name_hack} %}"
  liquid << "<abbr title=\"#{schema['description']}\">#{schema['title']}</abbr>: "
  if 'url'.eql?(schema.fetch('format', ''))
    liquid << "<a itemprop=\"#{name_hack}\" href=\"{{ page.#{name_hack} }}\">{{ page.#{name_hack} }}</a>"
  else
    liquid << "<span itemprop=\"#{name_hack}\">{{ page.#{name_hack} }}</span>"
  end
  liquid << linesep if linesep
  liquid << "{% endif %}\n"
  return liquid
end

# Transform JSON Schema into Jekyll Liquid templates
# NOTE: only creates partial template; manual tweaking necessary
def schema2liquid(infile, linesep)
  liquid = <<~LIQUID_HEADER
  ---
  layout: default
  ---
  LIQUID_HEADER
  schema = JSON.parse(File.read(infile))
  properties = schema['properties']
  properties.each do |fieldname, hash|
    if 'object'.eql?(hash['type'])
      liquid << emit_schema_object(nil, fieldname, hash, linesep)
    else
      liquid << emit_schema_scalar(nil, fieldname, hash, linesep)
    end
  end
  return liquid
end

# Transform JSON into Jekyll frontmatter
def json2jekyll(infile, outfile)
  jekyll = '' # NOTE: YAML.dump outputs document separator
  olddata = JSON.parse(File.read(infile))
  json = {}
  json['identifier'] = File.basename(infile, '.json') # Force to be first
  json['commonName'] = File.basename(infile, '.json')
  json = json.merge(olddata['20240101']) # Hack for CURRENT_SPONSORSHIP
  jekyll << YAML.dump(json)
  jekyll << "---\n"
  File.open(outfile, 'w') do |file|
    file.write(jekyll)
  end
end

# ## ### #### ##### ######
# Check commandline options
def parse_commandline
  options = {}
  OptionParser.new do |opts|
    opts.on('-h', '--help') { puts "#{DESCRIPTION}\n#{opts}"; exit }
    opts.on('-oOUTFILE', '--out OUTFILE', 'Output filename for operation') do |out|
      options[:out] = out
    end
    opts.on('-iINFILE', '--in INFILE', 'Input filename for operation') do |infile|
      options[:infile] = infile
    end
    opts.on('-aACTION', '--action ACTION', 'What action/operation to do: jekyll, csv, liquid, json') do |action|
      options[:action] = action
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
  options[:infile] ||= '_data/foundations-schema.json'
  options[:out] ||= 'foundation-liquid.html'
  options[:action] ||= 'liquid'
  outext = '.md'

  case options[:action]
  when 'jekyll'
    puts "BEGIN #{__FILE__}.csv2jekyll(#{options[:infile]}, #{options[:out]}, #{outext})"
    lines = csv2jekyll(options[:infile], options[:out], outext)
    puts "END parsed csv rows: #{lines}"
  when 'csv'
    puts "BEGIN #{__FILE__}.csv2jsonschema(#{options[:infile]}, #{options[:out]})"
    lines = csv2jsonschema(options[:infile], options[:out])
    puts "END parsed csv rows: #{lines}"
  when 'liquid'
    LINESEP = "<br/>"
    puts "BEGIN #{__FILE__}.schema2liquid(#{options[:infile]}, #{LINESEP})"
    lines = schema2liquid(options[:infile], LINESEP)
    File.write(options[:out], lines)
  when 'json'
    puts "BEGIN #{__FILE__}.json2jekyll(#{options[:infile]}, #{options[:out]})"
    if File.directory?(options[:infile])
      puts "BEGIN #{__FILE__}.json2jekyll(#{options[:infile]}) directory *.json processing"
      Dir["#{options[:infile]}/*.json"].each do |f|
        json2jekyll(f, f.sub('.json', '.md'))
      end
    else
      puts "BEGIN #{__FILE__}.json2jekyll(#{options[:infile]}) file processing"
      json2jekyll(options[:infile], options[:out])
    end
  else
    puts "Sorry, only support jekyll|csv|liquid|json options."
  end
end
