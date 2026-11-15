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
end
