# frozen_string_literal: true
# SPDX-License-Identifier: Apache-2.0

# Unit tests for the money Liquid filters in _plugins/money_filter.rb
# Run from project root: ruby assets/ruby/test/money_filter_test.rb
require 'minitest/autorun'
require_relative '../../../_plugins/money_filter'

class MoneyFilterTest < Minitest::Test
  include FossFoundation::MoneyFilter

  def test_money_short_amounts
    assert_equal '$2.31M', money(2_313_188)
    assert_equal '$2M', money('2000000')
    assert_equal '$1.25B', money(1_250_000_000)
    assert_equal '$950K', money(950_000)
    assert_equal '$12.5K', money(12_480)
    assert_equal '$500', money(500)
    assert_equal '$0', money(0)
    assert_equal '-$1.5M', money(-1_500_000)
    assert_equal '$2.5M', money('$2,500,000')
  end

  def test_dollars_exact_amounts
    assert_equal '$2,313,188', dollars(2_313_188)
    assert_equal '$999', dollars('999')
    assert_equal '-$1,000', dollars(-1000)
    assert_equal '$1,235', dollars(1234.6)
  end

  def test_blank_or_text_input
    ['', nil, 'TBD', '2.5M'].each do |input|
      assert_equal '', money(input), input.inspect
      assert_equal '', dollars(input), input.inspect
    end
  end
end
