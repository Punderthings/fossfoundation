#!/usr/bin/env ruby
# SPDX-License-Identifier: Apache-2.0
module OpenapiBuilder
  DESCRIPTION = <<-HEREDOC
  OpenapiBuilder: Simplistic CI tool to update openapi bits.
    Run from project root: ruby assets/ruby/openapi_builder.rb
    Writes _foundations/list.json from the _foundations/*.md records.
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

  # ### #### ##### ######
  # Main method for command line use
  if __FILE__ == $PROGRAM_NAME
    dir = File.join(Dir.pwd, '_foundations')
    list = build_list(dir)
    File.open(File.join(dir, 'list.json'), "w") do |f|
      f.write(JSON.pretty_generate(list))
    end
  end
end
