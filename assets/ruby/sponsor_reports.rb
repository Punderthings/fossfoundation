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

  INKIND_DISCOUNT = 0.5 # Discount value from sponsor of in-kind levels

  # Report total (approx) cash outlay by sponsors accross all orgs
  # in-kind donations are counted at INKIND_DISCOUNT of value (arbitrary estimate)
  # @param orglist output of sponsor_utils listing org sponsors scraped
  # @param levels definition of sponsorship levels by org
  def sponsor_totals(orglist, levels)
    report = {}
    report['orgtotal'] = {}
    report['sponsortotal'] = Hash.new(0)
    orglist.each do | org, sponsors |
      orgtotal = 0
      report['orgtotal'][org] = {}
      sponsors.each do | lvl, ary |
        lvlamt = levels[org][0]['levels'][lvl][1].to_i
        numlvl = ary.size
        amtlvl = lvlamt * numlvl
        # For the organization's report, count full value for all
        report['orgtotal'][org][lvl] = amtlvl
        orgtotal += amtlvl
        # For the sponsor's report, discount inkind levels
        ary.each do | sponsorurl |
          # TODO map any non-hostnames intelligently
          # TODO use /inkind/ INKIND_DISCOUNT
          # report['sponsortotal'][sponsorurl] += lvlamt # HACK this line randomly throws: undefined method `+' for nil:NilClass
          # HACK sum up values the hard way
          val = report['sponsortotal'].fetch(sponsorurl, nil)
          if val
            report['sponsortotal'][sponsorurl] += lvlamt
          else
            report['sponsortotal'][sponsorurl] = lvlamt
          end
        end
      end
      report['sponsortotal'] = Hash[report['sponsortotal'].sort_by { |k, v| -v }]
    end
    return report
  end

  # ### #### ##### ######
  # Main method for command line use
  if __FILE__ == $PROGRAM_NAME
    # TODO: default dir? Command line params? Load each sponsor level by org?
    levelfile = 'sponsor_levels.json'
    orgfile = 'sponsor_utils.json'
    levels = JSON.parse(File.read(levelfile))
    orglist = JSON.parse(File.read(orgfile))
    report = sponsor_totals(orglist, levels)
    File.open('sponsor_report.json', "w") do |f|
      f.write(JSON.pretty_generate(report))
    end
  end
end
