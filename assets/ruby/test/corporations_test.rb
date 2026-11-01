# frozen_string_literal: true

# SPDX-License-Identifier: Apache-2.0

# Tests for Corporations and the corporations report; no network access needed.
# Run from project root: ruby assets/ruby/test/corporations_test.rb
require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'json'
require_relative '../corporations'
require_relative '../sponsor_reports'

class CorporationsTest < Minitest::Test
  ROOT = File.expand_path('../../..', __dir__)
  SCHEMA = File.join(ROOT, '_data', 'corporations-schema.json')

  def rec(id, domains, extra = {})
    { 'identifier' => id, 'commonName' => id.capitalize, 'entityType' => 'Corporation',
      'website' => "https://#{domains.first}/", 'domains' => domains }.merge(extra)
  end

  def test_load_all_reads_front_matter
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'acme.md'),
                 "---\n# A comment\nidentifier: acme\ndomains:\n- acme.com\n---\n")
      assert_equal({ 'acme' => { 'identifier' => 'acme', 'domains' => ['acme.com'] } }, Corporations.load_all(dir))
    end
  end

  def test_load_all_rejects_non_hash
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'bad.md'), "---\n- a list\n---\n")
      assert_raises(SponsorUtils::ParseError) { Corporations.load_all(dir) }
    end
  end

  def test_resolve_uses_sponsor_normalization
    index = Corporations.domain_index({ 'meta' => rec('meta', ['meta.com']),
                                        'amazon' => rec('amazon', ['amazon.com']) })
    assert_equal 'meta', Corporations.resolve('meta.com', index)
    assert_equal 'meta', Corporations.resolve('facebook.com', index), 'host_aliases.json maps facebook.com to meta.com'
    assert_equal 'amazon', Corporations.resolve('aws.amazon.com', index),
                 'subdomains collapse to the registrable domain'
    assert_equal 'amazon', Corporations.resolve('https://www.amazon.com/foo', index)
    assert_nil Corporations.resolve('example.org', index)
  end

  def test_check_passes_clean_records
    corps = { 'acme' => rec('acme', ['acme.com']),
              'sub' => rec('sub', ['sub-brand.com'], 'parentOrganization' => [{ 'identifier' => 'acme' }]) }
    assert_equal [], Corporations.check(corps, { 'asf' => '_foundations' })
  end

  def test_check_finds_problems
    corps = { 'acme' => rec('acme', ['acme.com', 'www.acme.com']),
              'dup' => rec('dup', ['acme.com']),
              'Bad_Id' => rec('other', ['other.com'], 'parentOrganization' => [{ 'identifier' => 'nobody' }]),
              'asf' => rec('asf', ['apache-example.com']),
              'none' => rec('none', ['none.com']).merge('domains' => []) }
    problems = Corporations.check(corps, { 'asf' => '_foundations' })
    assert_includes problems, 'acme: domain www.acme.com is not canonical; sponsor data uses acme.com'
    assert_includes problems, 'domain acme.com is listed by more than one corporation: acme, dup'
    assert_includes problems, "Bad_Id: identifier 'other' does not match the file name"
    assert_includes problems, 'Bad_Id: identifier must use only lowercase letters, digits and hyphens'
    assert_includes problems, 'Bad_Id: parentOrganization nobody has no record in _corporations'
    assert_includes problems, 'asf: identifier is already used in _foundations'
    assert_includes problems, 'none: needs at least one domain'
  end

  def test_report_corporations_joins_by_domain
    corps = { 'acme' => rec('acme', ['acme.com']), 'idle' => rec('idle', ['idle.com']) }
    sponsors = { 'zfdn' => { 'first' => %w[acme.com], 'parseDate' => '20250101' },
                 'afdn' => { 'second' => %w[other.com acme.com], 'secondinkind' => %w[acme.com] } }
    funding = { 'sponsors' => { 'acme.com' => 1500, 'other.com' => 10 } }
    report = SponsorReports.report_corporations(sponsors, funding, corps)
    assert_equal %w[acme idle], report.keys, 'sorted by estimate'
    assert_equal({ 'estimate' => 1500, 'domains' => ['acme.com'],
                   'foundations' => { 'afdn' => %w[second secondinkind], 'zfdn' => %w[first] } }, report['acme'])
    assert_equal({ 'estimate' => 0, 'domains' => [], 'foundations' => {} }, report['idle'])
  end

  # The committed records themselves: cross-file rules and the schema's shape
  def test_repository_records_are_consistent
    Dir.chdir(ROOT) do
      corps = Corporations.load_all
      refute_empty corps
      assert_equal [], Corporations.check(corps, Corporations.other_ids)
    end
  end

  def test_repository_records_match_schema_shape
    schema = JSON.parse(File.read(SCHEMA))
    allowed = schema['properties'].keys
    types = schema.dig('properties', 'entityType', 'enum')
    Dir.chdir(ROOT) do
      Corporations.load_all.each do |id, record|
        assert_empty schema['required'] - record.keys, "#{id}: missing required fields"
        assert_empty record.keys - allowed, "#{id}: fields not in the schema"
        assert_includes types, record['entityType'], "#{id}: entityType"
        Array(record['sources']).each do |src|
          assert_equal %w[detail observed url], src.keys.sort, "#{id}: source fields"
        end
      end
    end
  end
end
