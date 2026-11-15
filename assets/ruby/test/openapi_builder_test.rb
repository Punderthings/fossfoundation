# frozen_string_literal: true

# SPDX-License-Identifier: Apache-2.0

# Tests for OpenapiBuilder (_foundations/list.json); no network access needed.
# Run from project root: ruby assets/ruby/test/openapi_builder_test.rb
require 'minitest/autorun'
require 'tmpdir'
require_relative '../openapi_builder'

# Tests for reading foundation records and building list.json
class OpenapiBuilderTest < Minitest::Test
  ROOT = File.expand_path('../../..', __dir__)

  def write(dir, name, frontmatter, body = "One sentence.\n")
    File.write(File.join(dir, name), "---\n#{frontmatter}---\n\n#{body}")
  end

  def test_build_list_names_domain_and_names_sorted_by_id
    Dir.mktmpdir do |dir|
      write(dir, 'zeta.md', "identifier: zeta\ncommonName: Zeta\nlegalName: Zeta Inc\nwebsite: https://www.zeta.org/\n")
      write(dir, 'alpha.md', "identifier: alpha\ncommonName: Alpha\nlegalName: Alpha\nwebsite: http://alpha.org\n")
      list = OpenapiBuilder.build_list(dir)
      assert_equal %w[alpha zeta], list.keys
      assert_equal ['alpha.org', 'Alpha'], list['alpha']
      assert_equal ['zeta.org', 'Zeta', 'Zeta Inc'], list['zeta']
    end
  end

  def test_missing_website_and_dates_are_handled
    Dir.mktmpdir do |dir|
      write(dir, 'nosite.md', "identifier: nosite\ncommonName: No Site\nwebsite:\nfoundingDate: 2001-02-03\n")
      assert_equal({ 'nosite' => ['', 'No Site'] }, OpenapiBuilder.build_list(dir))
    end
  end

  def test_files_without_identifier_are_skipped
    Dir.mktmpdir do |dir|
      write(dir, 'ok.md', "identifier: ok\ncommonName: Ok\nwebsite: https://ok.org/\n")
      File.write(File.join(dir, 'notes.md'), "No front matter here.\n")
      write(dir, 'noid.md', "commonName: Nobody\n")
      _out, err = capture_io { assert_equal %w[ok], OpenapiBuilder.build_list(dir).keys }
      assert_match(/Skipping .*notes\.md/, err)
      assert_match(/Skipping .*noid\.md/, err)
    end
  end

  def test_every_real_foundation_is_listed
    dir = File.join(ROOT, '_foundations')
    list = OpenapiBuilder.build_list(dir)
    assert_equal Dir.glob(File.join(dir, '*.md')).size, list.size
  end

  def test_plain_text_drops_markdown
    text = "see [attestors](crosswalk#attestors)\nand **`code`**"
    assert_equal 'see attestors and code', OpenapiBuilder.plain_text(text)
  end

  def test_distribution_urls
    site = 'https://example.org'
    dir = OpenapiBuilder.catalog_distribution({ 'path' => '_data/p990/', 'mediaType' => 'application/json' }, site)
    assert_equal 'https://github.com/Punderthings/fossfoundation/tree/main/_data/p990', dir['dcat:accessURL']['@id']
    refute dir.key?('dcat:downloadURL')
    refute dir.key?('dct:license')
    file = OpenapiBuilder.catalog_distribution({ 'path' => 'api/v2/x.json', 'license' => 'CC0-1.0' }, site)
    assert_equal 'https://example.org/api/v2/x.json', file['dcat:downloadURL']['@id']
    assert_equal 'https://spdx.org/licenses/CC0-1.0', file['dct:license']['@id']
  end

  def test_mixed_licenses_stay_on_distributions
    dists = [{ 'path' => 'a/', 'license' => 'Apache-2.0' }, { 'path' => 'b/', 'license' => 'CC0-1.0' }]
    entry = { 'identifier' => 'x', 'title' => 'X', 'page' => 'x', 'description' => 'X', 'distributions' => dists }
    refute OpenapiBuilder.catalog_dataset(entry, {}, 'https://example.org').key?('dct:license')
  end
end
