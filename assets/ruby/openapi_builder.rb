#!/usr/bin/env ruby
module OpenapiBuilder
  DESCRIPTION = <<-HEREDOC
  OpenapiBuilder: Simplistic CI tool to update openapi bits.
  HEREDOC
  module_function
  require 'yaml'
  require 'json'
  require_relative 'foundation_reporter.rb'

  # Build api:_foundations/list data structure
  # TODO replace this with a curated aliasOf feature instead
  # @return hash of foundation ids => array of alternate ids
  def build_list(dir)
    data = FoundationReporter.get_yamldataset(dir)
    list = {}
    data.each do | id, hash |
      list[id] = []
      list[id] << hash['website'].sub(/^https?\:\/\/(www.)?/,'').chomp('/')
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
