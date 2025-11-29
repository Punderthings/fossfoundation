#!/usr/bin/env ruby
module SchemaUtils
  DESCRIPTION = <<-HEREDOC
  Transformation utilities for csv data into json/yaml/md data.
  - Transform spreadsheet data rows into individual .md files with frontmatter.
  Each row becomes a name.md file, where each column value becomes a header:value pair of YAML frontmatter.
  HEREDOC

  module_function
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

  # Emit liquid template for a single value
  # @param fieldname string of this schema object
  # @param schema hash to process and emit liquid for
  # @return fragment string of liquid statement
  def emit_schema_valuespan(fieldname, schema)
    liquid = ''
    if 'url'.eql?(schema.fetch('format', ''))
      liquid << "<a itemprop=\"#{fieldname}\" href=\"{{ page.#{fieldname} }}\">{{ page.#{fieldname} }}</a>"
    else
      liquid << "<span itemprop=\"#{fieldname}\">{{ page.#{fieldname} }}</span>"
    end
    return liquid
  end

  # Emit liquid template for a scalar field
  # @param parentname string of this schema object that contains this field
  # @param fieldname string of this schema object
  # @param schema hash to process and emit liquid for
  # @param indent to use at this level
  # @param linesep to use if needed
  # @return single line string of liquid statements
  def emit_schema_scalar(parentname, fieldname, schema, indent, linesep)
    name_hack = parentname ? "#{parentname}.#{fieldname}" : fieldname
    liquid = "#{indent}{% if page.#{name_hack} %}"
    liquid << "<abbr title=\"#{schema['description']}\">#{schema['title']}</abbr>: "
    liquid << emit_schema_valuespan(name_hack, schema)
    liquid << "#{linesep}" if linesep
    liquid << "{% endif %}\n"
    return liquid
  end

  # Emit liquid template for array as a title and ul list
  # @param fieldName string of this schema object
  # @param schema hash to process and emit liquid for
  # @param indent to use at this level
  # @param linesep to use if needed
  # @return multiline string of liquid statements
  def emit_schema_array(fieldname, schema, indent, linesep)
    liquid = "#{indent}{% if page.#{fieldname} %}\n"
    liquid << "#{indent}<abbr title=\"#{schema['description']}\">#{schema['title']}</abbr>:\n"
    liquid << "#{indent}<ul>\n" # TODO: add class for styling
    liquid << "#{indent}  {% for loopitem in page.#{fieldname} %}\n"
    liquid << "#{indent}  <li><span itemprop=\"#{fieldname}\">{{ loopitem }}</span></li>\n" # FIXME: process format:url as well
    liquid << "#{indent}  {% endfor %}\n"
    liquid << "#{indent}</ul>\n"
    liquid << "#{indent}#{linesep}" if linesep
    liquid << "#{indent}{% endif %}\n"
    return liquid
  end

  # HACK emit liquid template for nested hash/array schema objects (recursive)
  # @param parentname string of this schema object that contains other objects
  # @param schema hash to process and emit liquid for
  # @param indent to use at this level
  # @param linesep to use if needed
  # @return multiline string of liquid statements
  def emit_schema_object(parentname, childname, schema, indent, linesep)
    liquid = ''
    name_hack = parentname ? "#{parentname}.#{childname}" : childname
    properties = schema['properties']
    properties.each do |itmname, hash|
      if 'object'.eql?(hash['type'])
        liquid << "#{indent}{% if page.#{name_hack}.#{childname}.#{itmname} %}\n"
        liquid << emit_schema_object(name_hack, itmname, hash, indent, linesep)
        liquid << linesep if linesep
        liquid << "{% endif %}\n"
      else
        liquid << emit_schema_scalar(name_hack, itmname, hash, indent, linesep)
      end
    end
    return liquid
  end

  # Parse a JSON Schema file into a hash
  def parse_schema(infile)
    schema = JSON.parse(File.read(infile))
    return schema
  end

  # Transform JSON Schema into partial Jekyll Liquid templates
  def schema2liquid(schema, linesep)
    liquid = ''
    indent = '    ' # FIXME if we want to nest inside existing layout
    fieldnames = []
    properties = schema['properties']
    firstsection = true
    properties.each do |fieldname, hash|
      fieldnames << fieldname
      section = hash.fetch('section', nil)
      if section
        if firstsection
          firstsection = false
        else
          liquid << "  </section>\n"
        end
        liquid << "  <section id=\"#{section.downcase}-section\">\n"
        liquid << "#{indent}<h2 id=\"#{section.downcase}\">#{section}</h2>\n"
      end
      if 'object'.eql?(hash['type'])
        liquid << emit_schema_object(nil, fieldname, hash, indent, linesep)
      elsif 'array'.eql?(hash['type'])
        liquid << emit_schema_array(fieldname, hash, indent, linesep)
      else
        liquid << emit_schema_scalar(nil, fieldname, hash, indent, linesep)
      end
    end
    liquid << "  </section>\n"
    puts "--- DEBUG List of fieldnames parsed:"
    puts "#{fieldnames}"
    return liquid
  end

  # Transform JSON Schema into template.md file for the type
  def schema2template(schema, body)
    template = "---\n"
    properties = schema['properties']
    properties.each do |fieldname, hash|
      next if hash.fetch('$comment', '').start_with?('EXCLUDE')
      template << "#{fieldname}:\n"
    end
    template << "---\n\n#{body}\n"
    return template
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

  YAML_SEP = '---'
  # FIXME: Don't include dissolutionDate in default fields (usage currently rare)
  # TODO: coordinate with schema definition automatically (generate this from foundation-schema.json ?)
  FOUNDATION_FIELDNAMES = %w[identifier	commonName	legalName	description	contacturl	website	foundingDate	addressCountry	addressRegion	newProjects	softwareType	wikidataId	boardSize	boardType	boardurl	teamurl	missionurl	bylawsurl	numberOfEmployees	governanceOrg	governanceTech	projectsNotable	projectsList	projectsServices	eventurl	nonprofitStatus	taxID	taxIDLocal	budgetUsd	budgetYear	budgeturl	budgetTransparent	funding	donateurl	sponsorurl	sponsorList	sponsorships	licenses	claPolicy	securityurl	ethicsPolicy	conducturl	conductEvents	conductSource	conductLinked	diversityPolicy	diversityDescription	brandPrimary	brandSecondary	brandReg	brandPolicy	brandUse	brandComments	logo	logoReg	subOrganization]
  # Normalize a .md file to have frontmatter fields in schema order
  # NOTE lossy; loses comments; places all non-schema fields at end of frontmatter
  # @param filename to read with frontmatter (markdown body left as-is)
  # @param fieldnames array of frontmatter fields in order; default FOUNDATION_FIELDNAMES
  # @return string describing our results
  def normalize_file(filename, fieldnames = FOUNDATION_FIELDNAMES)
    begin
      data = File.read(filename)
      _unused, frontmatter, markdown = data.split(YAML_SEP, 3) # YAML data separator
      markdown = '' if markdown.nil?
      yaml = YAML.safe_load(frontmatter, aliases: true)
      # Dump normalized data that's expected back to a file; note this removes # comments
      newyaml = {}
      fieldnames.each do | fieldname |
        newyaml[fieldname] = yaml.delete(fieldname)
      end
      # If any non-nil existing fields are left, add at end
      # FIXME decide how strict our data needs to be
      yaml.compact!
      yaml.each do | k, v |
        newyaml[k] = v
      end
      output = newyaml.to_yaml
      output << YAML_SEP # Note: newline provided by shovel operator below
      output << markdown
      outputfilename = filename # NOTE overwrite files
      File.open(outputfilename, 'w') do |f|
        f.puts output
      end
      return "Wrote out: #{outputfilename}"
    rescue StandardError => e
      return "ERROR: normalize_md(#{filename}): #{e.message}\n\n#{e.backtrace.join("\n\t")}"
    end
  end

  # Normalize md files into fieldnames order; return report of what's done
  #   SIDE EFFECTS: rewrites files; may lose # yaml comments
  # @param directory to scan all .md files
  # @param fieldlist of fields to force output in order
  # @return array of strings describing each action
  def normalize_dataset(dir, fieldnames)
    report = []
    Dir["#{dir}/*.md"].each do |f|
      report << normalize_file(f, fieldnames)
    end
    return report
  end

  # Approximately transform a schema into csv describing fields in order
  # NOTE: lossy, does not cover complex fields
  # @param infile to parse
  def schema2csv(infile)
    outfile = infile.sub('.json', '.csv')
    schema = JSON.parse(File.read(infile))
    properties = schema['properties']
    CSV.open(outfile, "w", headers: %w( identifier title type format description  ), write_headers: true) do |csv|
      properties.each do | id, hash |
        csv << [ id, hash.fetch('title', ''), hash.fetch('type', ''), hash.fetch('format', ''), hash.fetch('description', '') ]
      end
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
      opts.on('-tTEMPLATEOUT', '--template TEMPLATEOUT', 'Output filename for template data') do |outtemplate|
        options[:outtemplate] = outtemplate
      end
      opts.on('-iINFILE', '--in INFILE', 'Input filename for operation') do |infile|
        options[:infile] = infile
      end
      opts.on('-aACTION', '--action ACTION', 'What action/operation to do: jekyll, csv, liquid, json, normalize') do |action|
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
    options[:action] ||= 'liquid'
    if 'liquid'.eql?(options[:action])
      options[:out] ||= '_includes/foundation-fields.html'
      options[:outtemplate] ||= '_data/foundation-template.md'
    end
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
    when 'liquid' # Produce both liquid layout and template.md
      linesep = "<br/>"
      body = "FOUNDATION_TEMPLATE To add a listing for a new non-profit foundation, copy this file and then fill in as much data as you can verify against official sources (from that foundation, not just wikipedia or the like) in the YAML frontmatter fields above.  The data schema is in the foundations-schema.json file.  Then replace this section (i.e. the content of a Jekyll document) with a one sentence factual description of the organization as a whole.  Submit a PR with this new identifier.md file in the _foundations directory."
      puts "BEGIN #{__FILE__}.schema2liquid(#{options[:infile]}, #{linesep})"
      schema = parse_schema(options[:infile])
      lines = schema2liquid(schema, linesep)
      File.write(options[:out], lines)
      puts "...wrote liquid to #{options[:out]}; WARNING: manual tweaking likely needed"
      lines = schema2template(schema, body)
      File.write(options[:outtemplate], lines)
      puts "END wrote template to #{options[:outtemplate]}"
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
    when 'normalize'
      puts "BEGIN #{__FILE__}.normalize_md('_foundations'...)"
      lines = normalize_dataset('_foundations', FOUNDATION_FIELDNAMES)
      File.write('schema_utils_normalize.txt', JSON.pretty_generate(lines))
    else
      puts "WARNING: unsupported option, see -h."
    end
  end
end
