#!/usr/bin/env ruby
module SponsorReports
  DESCRIPTION = <<-HEREDOC
  SponsorReports: Build simple reports from SponsorUtils data.
  Default to run from project root directory.
  HEREDOC
  module_function
  require 'csv'
  require 'yaml'
  require 'json'
  require_relative 'sponsor_utils'

  INKIND_DISCOUNT = 0.5 # Discount value from sponsor of in-kind levels

  # Report total (approx) cash outlay by sponsors accross all orgs
  # in-kind donations are counted at INKIND_DISCOUNT of value (arbitrary estimate)
  # @param orglist output of sponsor_utils listing org sponsors scraped
  # @return hash of estimated funding levels by org or sponsor
  def report_funding(allsponsors)
    report = {}
    report['orgtotal'] = {}
    report['sponsortotal'] = Hash.new(0)
    allsponsors.each do | org, sponsors |
      orgtotal = 0
      report['orgtotal'][org] = {}
      orglevels = SponsorUtils.get_current_sponsorship(SponsorUtils.get_sponsorship_file(org))
      orglevels = orglevels['levels']
      sponsors.each do | lvl, ary |
        next unless ary.is_a?(Array)
        lvlamt = orglevels[lvl].fetch('amount', 0).to_i
        numlvl = ary.size
        amtlvl = lvlamt * numlvl
        # For the organization's report, count full value for all
        report['orgtotal'][org][lvl] = amtlvl
        orgtotal += amtlvl
        # For the sponsor's report, discount inkind levels
        if ary.is_a?(Array) # Ignore dates or errors
          ary.each do | sponsorurl |
            # TODO somehow mark amountvaries levels
            # TODO map any non-hostnames intelligently
            lvlamt = (lvlamt * INKIND_DISCOUNT).round(0) if /inkind/.match(lvl)
            # report['sponsortotal'][sponsorurl] += lvlamt # HACK1 this line randomly throws: undefined method `+' for nil:NilClass
            # HACK1 sum up values the hard way
            val = report['sponsortotal'].fetch(sponsorurl, nil)
            if val
              report['sponsortotal'][sponsorurl] += lvlamt
            else
              report['sponsortotal'][sponsorurl] = lvlamt
            end
          end
        end
      end
      report['sponsortotal'] = Hash[report['sponsortotal'].sort_by { |k, v| -v }]
    end
    return report
  end

  # Rough count of number of times different urls appear at levels
  # @param sponsors hash returned from scrape_bycss or parse_landscape
  # @return hash of counts of how often domain names appear
  def report_counts(sponsors)
    counts = {}
    counts['orgs'] = []
    counts['all'] = Hash.new(0)
    SponsorUtils::SPONSOR_METALEVELS.each do | lvl |
      counts[lvl] = Hash.new(0)
    end
    sponsors.each do | org, sponsorhash |
      counts['orgs'] << org
      if sponsorhash.is_a?(Hash) # Ignore dates or possible error entries
        sponsorhash.each do | level, ary |
          if ary.is_a?(Array)  # Ignore dates or possible error entries
            ary.each do | url |
              counts['all'][url] += 1
              counts[level][url] += 1
            end
          end
        end
      end
    end
    counts['all'] = Hash[counts['all'].sort_by { |k, v| -v }]
    SponsorUtils::SPONSOR_METALEVELS.each do | lvl |
      counts[lvl] = Hash[counts[lvl].sort_by { |k, v| -v }]
    end
    return counts
  end

  # ### #### ##### ######
  # Main method for command line use
  if __FILE__ == $PROGRAM_NAME
    # TODO: default dir? Command line params? Load each sponsor level by org?
    infile = '_data/allsponsorships.json'
    levelfile = '_data/allsponsorreports.json'
    fundfile = '_data/allsponsorfunds.json'
    sponsors = JSON.parse(File.read(infile))
    report = report_counts(sponsors)
    File.open(levelfile, "w") do |f|
      f.write(JSON.pretty_generate(report))
    end
    report = report_funding(sponsors)
    File.open(fundfile, "w") do |f|
      f.write(JSON.pretty_generate(report))
    end
  end
end
