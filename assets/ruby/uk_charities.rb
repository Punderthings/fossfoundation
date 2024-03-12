#!/usr/bin/env ruby
module UKCharities
  DESCRIPTION = <<-HEREDOC
  UKCharities: Lookup charity details from UK Register of Charities.
  https://register-of-charities.charitycommission.gov.uk/documentation-on-the-api
  HEREDOC
  module_function
  require 'yaml'
  require 'json'
  require 'csv'
  require 'faraday'
  require 'optparse'

  CHARITYCOMMISSION_HOST = '''https://api.charitycommission.gov.uk'''
  CHARITYCOMMISSION_ACTION = '/register/api/allcharitydetailsV2/'

  # Get full report of a single charity
  # @param registeredNumber of charity from taxID field
  # @param apiToken to access charitycommission.gov.uk
  # @return UK charities data
  def get_charity(registeredNumber, apiToken)
    charity = {}
    faraday = Faraday.new(url: CHARITYCOMMISSION_HOST) do |config|
      config.request :authorization, :bearer, apiToken
      config.response :raise_error
      config.adapter :net_http
    end
    faraday.headers['Authorization'] = "APIKEY #{apiToken}"
    response = faraday.get("#{CHARITYCOMMISSION_ACTION}#{registeredNumber}")
    puts "DEBUG #{response.status}"
    puts "DEBUG #{JSON.pretty_generate(response.headers)}"
    charity = response.body
    return charity
  end
end

# ### #### ##### ######
# Main method for command line use
if __FILE__ == $PROGRAM_NAME
  # options = UKCharities.parse_commandline
  options = {}
  options[:outfile] ||= 'uk_charities.json'
  options[:taxID] ||= '1129409'
  fixme = 'api key would go here'
  output = UKCharities.get_charity(options[:taxID], fixme)
  File.open(options[:outfile], "w") do |f|
    f.write(JSON.pretty_generate(output))
  end
end
