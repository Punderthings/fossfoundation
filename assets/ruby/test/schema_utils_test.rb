# frozen_string_literal: true

# SPDX-License-Identifier: Apache-2.0

# Tests that foundation field lists come from _data/foundations-schema.json; no network access needed.
# Run from project root: ruby assets/ruby/test/schema_utils_test.rb
require 'minitest/autorun'
require_relative '../schema_utils'

# Tests for field order and the foundation template, both read from the schema
class SchemaUtilsTest < Minitest::Test
  def schema
    @schema ||= SchemaUtils.parse_schema(SchemaUtils::FOUNDATIONS_SCHEMA)
  end

  def test_fieldnames_follow_schema_order_and_leave_out_excluded_fields
    expected = schema['properties'].keys - ['dissolutionDate']
    assert_equal expected, SchemaUtils::FOUNDATION_FIELDNAMES
  end

  def test_schema2template_writes_each_field_with_its_title
    small = { 'properties' => {
      'identifier' => { 'title' => 'Id' },
      'gone' => { 'title' => 'Gone', '$comment' => 'EXCLUDE unless needed' },
      'website' => { 'title' => 'Website' }
    } }
    assert_equal "---\nidentifier: # Id\nwebsite: # Website\n---\n\nBody\n", SchemaUtils.schema2template(small, 'Body')
  end

  def test_committed_template_matches_schema
    expected = SchemaUtils.schema2template(schema, SchemaUtils::FOUNDATION_TEMPLATE_BODY)
    assert_equal expected, File.read(SchemaUtils::FOUNDATION_TEMPLATE),
                 'Regenerate with: ruby assets/ruby/schema_utils.rb -a template'
  end

  def test_every_property_has_a_title_and_description_for_the_site
    schema['properties'].each do |name, prop|
      assert prop['title'], "#{name} needs a title"
      assert prop['description'], "#{name} needs a description"
    end
  end
end
