# frozen_string_literal: true

# SPDX-License-Identifier: Apache-2.0

# Tests for the dataset registry (_data/datasets.yml) and the DCAT catalog that
# OpenapiBuilder writes from it; no network access needed.
# Run from project root: ruby assets/ruby/test/datasets_test.rb
require 'minitest/autorun'
require_relative '../openapi_builder'

# Checks that the registry matches the repository, and the catalog matches the registry
class DatasetsTest < Minitest::Test
  ROOT = File.expand_path('../../..', __dir__)
  STATUSES = %w[published in-progress planned].freeze
  REQUIRED = %w[identifier title page description status maintained].freeze
  # Split so that REUSE does not read this file's own pattern as a license
  HEADER = /SPDX-License-(?:Identifier):\s*(\S+)/

  def registry
    @registry ||= YAML.safe_load_file(File.join(ROOT, OpenapiBuilder::DATASETS_FILE))
  end

  def datasets
    registry['datasets']
  end

  # Permalinks of the site pages, without the leading slash
  def permalinks
    @permalinks ||= Dir.glob(File.join(ROOT, '_pages', '*.md')).filter_map do |file|
      File.read(file, encoding: 'UTF-8')[/^permalink:\s*(\S+)/, 1]&.delete_prefix('/')
    end
  end

  # REUSE.toml annotations as [regexp, precedence, license]; a minimal reader for
  # this repository's own REUSE.toml, which uses only path, precedence and license
  def reuse_annotations
    @reuse_annotations ||= File.read(File.join(ROOT, 'REUSE.toml')).split('[[annotations]]').drop(1).map do |table|
      paths = table[/^path\s*=\s*(.+)$/, 1].scan(/"([^"]+)"/).flatten
      [Regexp.union(paths.map { |p| glob_regexp(p) }), table[/^precedence\s*=\s*"(\w+)"/, 1],
       table[/^SPDX-License-Identifier\s*=\s*"([^"]+)"/, 1]]
    end
  end

  def glob_regexp(glob)
    Regexp.new("\\A#{Regexp.escape(glob).gsub('\*\*', '.*').gsub(/(?<!\.)\\\*/, '[^/]*')}\\z")
  end

  # License of one file as REUSE resolves it: an override annotation, else the
  # file's own SPDX header, else the last matching closest annotation
  def reuse_license(relpath)
    matches = reuse_annotations.select { |re, _, _| re.match?(relpath) }
    override = matches.select { |_, precedence, _| precedence == 'override' }.last
    return override[2] if override

    file_header(relpath) || matches.select { |_, precedence, _| precedence == 'closest' }.last&.at(2)
  end

  def file_header(relpath)
    File.foreach(File.join(ROOT, relpath), encoding: 'UTF-8').first(5).join.scrub[HEADER, 1]
  end

  def files_of(path)
    return [path] unless path.end_with?('/')

    Dir.glob('**/*', base: File.join(ROOT, path)).map { |f| path + f }
       .reject { |f| File.directory?(File.join(ROOT, f)) }
  end

  def test_identifiers_are_unique
    assert_equal datasets.size, datasets.map { |d| d['identifier'] }.uniq.size
  end

  def test_entries_are_complete
    datasets.each do |d|
      id = d['identifier']
      REQUIRED.each { |k| assert d[k], "#{id}: no #{k}" }
      assert_includes STATUSES, d['status'], id
      assert d['schemas'] || d['schemaNote'], "#{id}: no schemas or schemaNote"
      assert d['distributions'] || d['where'], "#{id}: no distributions or where"
    end
  end

  def test_published_datasets_have_distributions_and_sourcing
    sourcing = registry['sourcing'].map { |s| s['identifier'] }
    datasets.select { |d| d['status'] == 'published' }.each do |d|
      refute_empty d.fetch('distributions', []), d['identifier']
      assert_includes sourcing, d['sourcing'], d['identifier']
    end
  end

  def test_pages_and_schemas_exist
    datasets.each do |d|
      assert_includes permalinks, d['page'].split('#').first, "#{d['identifier']}: no page #{d['page']}"
      d.fetch('schemas', []).each { |s| assert File.file?(File.join(ROOT, '_data', s)), s }
    end
  end

  def test_distribution_paths_have_files
    datasets.flat_map { |d| d.fetch('distributions', []) }.each do |dist|
      refute_empty files_of(dist['path']), "#{dist['path']} has no files"
    end
  end

  def test_licenses_match_reuse
    datasets.flat_map { |d| d.fetch('distributions', []) }.select { |dist| dist['license'] }.each do |dist|
      files_of(dist['path']).each do |file|
        assert_equal dist['license'], reuse_license(file), "#{file}: registry and REUSE disagree"
      end
    end
  end

  def test_reuse_reader_sees_known_licenses
    assert_equal 'CC0-1.0', reuse_license('_data/attestations.json')
    assert_equal 'CC0-1.0', reuse_license('_sponsors/google.md')
    assert_equal 'Apache-2.0', reuse_license('_foundations/asf.md')
    assert_equal 'CC0-1.0', reuse_license('api/v2/crosswalk/asf.json')
  end

  def test_committed_catalog_is_current
    committed = File.read(File.join(ROOT, OpenapiBuilder::CATALOG_FILE), encoding: 'UTF-8')
    assert_equal OpenapiBuilder.catalog_json(ROOT), committed,
                 'api/v2/catalog.jsonld is out of date; run ruby assets/ruby/openapi_builder.rb'
  end

  def test_catalog_lists_only_published_datasets
    catalog = JSON.parse(OpenapiBuilder.catalog_json(ROOT))
    ids = catalog['dcat:dataset'].map { |d| d['dct:identifier'] }
    assert_equal datasets.select { |d| d['status'] == 'published' }.map { |d| d['identifier'] }, ids
    refute_includes ids, 'budgets'
  end
end
