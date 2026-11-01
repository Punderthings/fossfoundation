#!/usr/bin/env ruby
# frozen_string_literal: true

# SPDX-License-Identifier: Apache-2.0
module Sponsors
  DESCRIPTION = <<-HEREDOC
  Sponsors: Load _sponsors records, resolve sponsor domains to them,
    and check that the records agree with the rest of the data.
    Run from the project root; --check exits non-zero on any problem.
    Plan: _prompts/2026-10-31-corporations-dataset-plan.md
  HEREDOC

  module_function

  require 'yaml'
  require 'date'
  require_relative 'sponsor_utils'

  SPONSORS_DIR = '_sponsors'
  # Other collections whose identifiers share one namespace with sponsor records
  OTHER_ID_DIRS = %w[_foundations _entities].freeze
  ID_PATTERN = /\A[a-z0-9-]+\z/

  # Read the front matter of one Jekyll document
  # @param path to a .md file
  # @return hash of front matter
  # @raise SponsorUtils::ParseError if it is not a YAML hash
  def read_front_matter(path)
    text = File.read(path, encoding: 'UTF-8')
    frontmatter = text[/\A---\s*\n(.*?)^---\s*$/m, 1] || text
    data = YAML.safe_load(frontmatter, permitted_classes: [Date], aliases: true)
    raise SponsorUtils::ParseError, "#{path}: front matter is not a hash" unless data.is_a?(Hash)

    return data
  rescue Psych::Exception => e
    raise SponsorUtils::ParseError, "#{path}: invalid YAML: #{e.message}"
  end

  # Load every sponsor record
  # @param dir pointing to _sponsors
  # @return hash of file id => record hash, sorted by id
  def load_all(dir = SPONSORS_DIR)
    records = {}
    Dir.glob(File.join(dir, '*.md')).sort.each do |file|
      records[File.basename(file, '.md')] = read_front_matter(file)
    end
    return records
  end

  # Map each sponsor domain to the sponsor record that lists it
  # @param records hash from load_all
  # @return hash of domain => sponsor id (the first record wins if two list it)
  def domain_index(records)
    index = {}
    records.each do |id, rec|
      Array(rec['domains']).each { |domain| index[domain.to_s.downcase] ||= id }
    end
    return index
  end

  # Resolve a sponsor value from any sponsor dataset to a sponsor id
  # The value is normalized the same way scrapers normalize sponsor links
  # (host_aliases.json, registrable domain) before the lookup
  # @param sponsor domain or URL as stored in sponsor data
  # @param index hash from domain_index
  # @return sponsor id, or nil if none lists it
  def resolve(sponsor, index)
    return index[sponsor.to_s.downcase] || index[SponsorUtils.normalize_href(sponsor).to_s.downcase]
  end

  # Identifiers already used by other collections
  # @param root project root
  # @return hash of id => directory it is used in
  def other_ids(root = '.')
    ids = {}
    OTHER_ID_DIRS.each do |dir|
      Dir.glob(File.join(root, dir, '*.md')).each { |file| ids[File.basename(file, '.md')] ||= dir }
    end
    return ids
  end

  # Check sponsor record against each other and the rest of the data
  # (schema shape is checked against _data/sponsors-schema.json separately)
  # @param records hash from load_all
  # @param taken hash from other_ids
  # @return array of problem strings; empty when all is well
  def check(records, taken = {})
    problems = []
    owners = Hash.new { |h, k| h[k] = [] }
    records.each do |id, rec|
      ident = rec['identifier'].to_s
      problems << "#{id}: identifier '#{ident}' does not match the file name" unless ident == id
      problems << "#{id}: identifier must use only lowercase letters, digits and hyphens" unless ID_PATTERN.match?(id)
      problems << "#{id}: identifier is already used in #{taken[id]}" if taken.key?(id)
      domains = Array(rec['domains'])
      problems << "#{id}: needs at least one domain" if domains.empty?
      domains.each do |domain|
        owners[domain.to_s.downcase] << id
        canonical = SponsorUtils.normalize_href(domain)
        next if canonical == domain

        problems << "#{id}: domain #{domain} is not canonical; sponsor data uses #{canonical}"
      end
      Array(rec['parentOrganization']).each do |parent|
        pid = parent.is_a?(Hash) ? parent['identifier'] : parent
        problems << "#{id}: parentOrganization #{pid} has no record in #{SPONSORS_DIR}" unless records.key?(pid)
        problems << "#{id}: parentOrganization cannot be itself" if pid == id
      end
    end
    owners.each do |domain, ids|
      problems << "domain #{domain} is listed by more than one sponsor: #{ids.join(', ')}" if ids.size > 1
    end
    return problems
  end

  # ### #### ##### ######
  # Main method for command line use
  if __FILE__ == $PROGRAM_NAME
    require 'optparse'
    OptionParser.new do |opts|
      opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [--check]\n#{DESCRIPTION}"
      opts.on('--check', 'Check all records (default action).')
    end.parse!
    records = load_all
    problems = check(records, other_ids)
    problems.each { |p| warn p }
    puts "#{records.size} sponsors, #{problems.size} problems"
    exit(problems.empty? ? 0 : 1)
  end
end
