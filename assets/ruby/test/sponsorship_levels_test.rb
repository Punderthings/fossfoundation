# frozen_string_literal: true

# SPDX-License-Identifier: Apache-2.0

# Tests that sponsorship metalevels and source types come from _data/sponsorships-schema.json;
# no network access needed. Run from project root: ruby assets/ruby/test/sponsorship_levels_test.rb
require 'minitest/autorun'
require 'yaml'
require_relative '../sponsor_utils'

# The levels properties of the sponsorships schema are the single list of metalevels
class SponsorshipLevelsTest < Minitest::Test
  ROOT = File.expand_path('../../..', __dir__)

  def schema_levels
    SponsorUtils::SPONSORSHIPS_SCHEMA.dig('properties', 'levels', 'properties')
  end

  def test_metalevels_are_the_schema_levels_in_rank_order
    assert_equal schema_levels.keys, SponsorUtils::SPONSOR_METALEVELS
    assert_equal %w[first second third], SponsorUtils::SPONSOR_METALEVELS.first(3)
    assert_equal 'listed', SponsorUtils::SPONSOR_METALEVELS.last
  end

  def test_every_level_has_a_title_and_description
    schema_levels.each do |level, prop|
      assert prop['title'], "#{level} needs a title, its display label"
      assert prop['description'], "#{level} needs a description"
    end
  end

  def test_inkind_levels_are_marked_in_the_schema
    assert_equal %w[firstinkind secondinkind thirdinkind fourthinkind], SponsorUtils::INKIND_LEVELS
  end

  def test_source_types_are_the_schema_enum
    assert_equal SponsorUtils::SPONSORSHIPS_SCHEMA.dig('properties', 'sourcetype', 'enum'), SponsorUtils::SOURCE_TYPES
  end

  def test_deprecated_label_file_matches_schema
    assert_equal "#{JSON.pretty_generate(SponsorUtils.level_labels)}\n", File.read(SponsorUtils::LEVEL_LABELS_FILE),
                 'Regenerate with: ruby assets/ruby/sponsor_reports.rb'
  end

  def model_levels(path)
    model = YAML.safe_load(File.read(path, encoding: 'UTF-8').split(/^---\s*$/, 3)[1], permitted_classes: [Date])
    ([model] + Array(model['pastModels'])).flat_map { |m| (m['levels'] || {}).keys }
  end

  def test_every_model_uses_known_levels
    Dir[File.join(ROOT, SponsorUtils::SPONSORSHIPS_DIR, '*.md')].each do |path|
      unknown = model_levels(path) - SponsorUtils::SPONSOR_METALEVELS
      assert_empty unknown, "#{File.basename(path)} uses levels not in the schema"
    end
  end
end
