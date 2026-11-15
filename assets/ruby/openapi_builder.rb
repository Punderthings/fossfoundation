#!/usr/bin/env ruby
# SPDX-License-Identifier: Apache-2.0
module OpenapiBuilder
  DESCRIPTION = <<-HEREDOC
  OpenapiBuilder: Simplistic CI tool to update openapi bits.
    Run from project root: ruby assets/ruby/openapi_builder.rb
    Writes _foundations/list.json from the _foundations/*.md records, and
    openapi/v1/foundation-schema.yaml from _data/foundations-schema.json.
  HEREDOC
  module_function
  require 'date'
  require 'yaml'
  require 'json'

  # Read the YAML front matter of one record
  # @param path to a .md file with front matter
  # @return hash, or nil if the front matter is missing or not a hash
  def read_front_matter(path)
    text = File.read(path, encoding: 'UTF-8')
    frontmatter = text[/\A---\s*\n(.*?)^---\s*$/m, 1]
    return nil unless frontmatter

    data = YAML.safe_load(frontmatter, permitted_classes: [Date])
    data.is_a?(Hash) ? data : nil
  end

  # Load every foundation record in a directory
  # @param dir pointing to _foundations
  # @return hash of identifier => record, sorted by identifier
  def load_records(dir)
    records = {}
    Dir.glob(File.join(dir, '*.md')).each do |file|
      data = read_front_matter(file)
      if data.nil? || !data.key?('identifier')
        warn "Skipping #{file}: no front matter with an identifier"
        next
      end
      records[data['identifier']] = data
    end
    records.sort.to_h
  end

  # Build api:_foundations/list data structure
  # TODO replace this with a curated aliasOf feature instead
  # @return hash of foundation ids => array of alternate ids
  def build_list(dir)
    data = load_records(dir)
    list = {}
    data.each do | id, hash |
      list[id] = []
      list[id] << hash['website'].to_s.sub(/^https?\:\/\/(www.)?/,'').chomp('/')
      cn = hash['commonName']
      ln = hash.fetch('legalName', nil)
      list[id] << cn
      if ln && !ln.eql?(cn)
          list[id] << hash['legalName']
      end
      # TODO are there any other alternate lookup methods to include?
    end
    return list
  end

  ROOT = File.expand_path('../..', __dir__)
  FOUNDATIONS_SCHEMA = File.join(ROOT, '_data', 'foundations-schema.json')
  FOUNDATION_OPENAPI = File.join(ROOT, 'openapi', 'v1', 'foundation-schema.yaml')
  # Version of the v1 API description; 1.1.0 is the first one generated from the JSON Schema
  OPENAPI_VERSION = '1.1.0'.freeze
  # JSON Schema keywords copied into the OpenAPI 3.0 schema; our own keywords (x-check,
  # x-includes, section) and non-standard formats are left out
  OPENAPI_KEYWORDS = %w[title description type format pattern enum items uniqueItems].freeze
  # Our formats that have an OpenAPI equivalent; any others are left out
  OPENAPI_FORMATS = { 'url' => 'uri', 'uri' => 'uri', 'date' => 'date' }.freeze
  OPENAPI_HEADER = <<~HEADER.freeze
    # GENERATED FILE: do not edit. Change _data/foundations-schema.json, then run
    #   ruby assets/ruby/openapi_builder.rb
    # Version 1.1.0 (2026-11-15) is the first version generated from the JSON Schema.
  HEADER
  OPENAPI_INFO = {
    'version' => OPENAPI_VERSION,
    'title' => 'FOSS Foundation metadata schema',
    'description' => 'Fields describing a FOSS foundation for https://fossfoundation.info/data'
  }.freeze
  OPENAPI_SERVERS = [{ 'description' => 'SwaggerHub API Auto Mocking',
                       'url' => 'https://virtserver.swaggerhub.com/ShaneCurcuru/foundation-schema/1.0.0' }].freeze

  # Convert one JSON Schema property to OpenAPI 3.0
  # @param prop hash of a JSON Schema property
  # @return hash with only the OpenAPI keywords, formats mapped
  def openapi_property(prop)
    prop.slice(*OPENAPI_KEYWORDS).filter_map do |key, value|
      case key
      when 'format' then [key, OPENAPI_FORMATS[value]] if OPENAPI_FORMATS[value]
      when 'items' then [key, openapi_property(value)]
      else [key, value]
      end
    end.to_h
  end

  # Build the v1 OpenAPI description of a foundation record from the JSON Schema
  # @param schema hash of _data/foundations-schema.json
  # @return hash to write as openapi/v1/foundation-schema.yaml
  def build_foundation_openapi(schema)
    foundation = {
      'type' => 'object',
      'title' => 'FOSS Foundation metadata schema',
      'required' => schema['required'],
      'properties' => schema['properties'].transform_values { |prop| openapi_property(prop) }
    }
    { 'openapi' => '3.0.0', 'info' => OPENAPI_INFO, 'paths' => {}, 'servers' => OPENAPI_SERVERS,
      'components' => { 'schemas' => { 'Foundation' => foundation } } }
  end

  # The text of openapi/v1/foundation-schema.yaml
  # @param schema hash of _data/foundations-schema.json
  # @return string of YAML with a header comment
  def foundation_openapi_yaml(schema)
    OPENAPI_HEADER + YAML.dump(JSON.parse(JSON.generate(build_foundation_openapi(schema))), line_width: -1)
  end

  # ### #### ##### ######
  # Main method for command line use
  if __FILE__ == $PROGRAM_NAME
    dir = File.join(Dir.pwd, '_foundations')
    list = build_list(dir)
    File.open(File.join(dir, 'list.json'), "w") do |f|
      f.write(JSON.pretty_generate(list))
    end
    File.write(FOUNDATION_OPENAPI, foundation_openapi_yaml(JSON.parse(File.read(FOUNDATIONS_SCHEMA))))
  end
end
