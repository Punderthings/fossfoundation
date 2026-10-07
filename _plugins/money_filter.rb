# frozen_string_literal: true
# SPDX-License-Identifier: Apache-2.0

# Liquid filters for US dollar amounts on foundation pages:
#   {{ 2313188 | money }}   => $2.31M
#   {{ 2313188 | dollars }} => $2,313,188
module FossFoundation
  module MoneyFilter
    # @return short dollar string ($1.2B, $2.31M, $950K, $500), or '' for blank or non-numeric input
    def money(input)
      MoneyFilter.short(input)
    end

    # @return exact dollar string with thousands separators, or '' for blank or non-numeric input
    def dollars(input)
      MoneyFilter.exact(input)
    end

    # @return Float, or nil if input is not a number
    def self.number(input)
      Float(input.to_s.delete(',$ '))
    rescue ArgumentError
      nil
    end

    def self.short(input)
      value = number(input) or return ''
      size = value.abs
      text = if size >= 1e9 then "#{trim(size / 1e9, 2)}B"
             elsif size >= 1e6 then "#{trim(size / 1e6, 2)}M"
             elsif size >= 1e3 then "#{trim(size / 1e3, 1)}K"
             else size.round.to_s
             end
      "#{'-' if value.negative?}$#{text}"
    end

    def self.exact(input)
      value = number(input) or return ''
      digits = value.abs.round.to_s.reverse.scan(/\d{1,3}/).join(',').reverse
      "#{'-' if value.negative?}$#{digits}"
    end

    # @return number rounded to digits places, without trailing zeros
    def self.trim(number, digits)
      Kernel.format('%.*f', digits, number).sub(/\.?0+\z/, '')
    end
  end
end

Liquid::Template.register_filter(FossFoundation::MoneyFilter) if defined?(Liquid::Template)
