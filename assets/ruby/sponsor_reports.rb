#!/usr/bin/env ruby
module SponsorReports
  DESCRIPTION = <<-HEREDOC
  SponsorReports: Build simple reports from SponsorUtils data.
    Default to run from project root directory.
    Note the word 'sponsorship' gets overloaded, depending on
    context refers to a model level definition, or a specific
    point in time sponsor -> org data.
  HEREDOC
  module_function
  require 'csv'
  require 'yaml'
  require 'json'
  require_relative 'sponsor_utils'

  INKIND_DISCOUNT = 0.5 # Discount value from sponsor of in-kind levels

  ORGS_REPORT = 'orgs'
  SPONSORS_REPORT = 'sponsors'
  TOTALS = 'total'

  # Report total (approx) cash outlay by sponsors accross all orgs
  # in-kind donations are counted at INKIND_DISCOUNT of value (arbitrary estimate)
  # @param orglist output of sponsor_utils listing org sponsors scraped
  # @return hash of estimated funding levels by org or sponsor
  def report_funding(allsponsors)
    alltotal = 0
    report = {}
    report[ORGS_REPORT] = {}
    report[SPONSORS_REPORT] = Hash.new(0)
    allsponsors.each do | org, sponsors |
      orgtotal = 0
      report[ORGS_REPORT][org] = {}
      orglevels = SponsorUtils.get_current_sponsorship(SponsorUtils.get_sponsorship_file(org))
      orglevels = orglevels['levels']
      sponsors.each do | lvl, ary |
        next unless ary.is_a?(Array)
        lvlamt = orglevels[lvl].fetch('amount', 0).to_i
        numlvl = ary.size
        amtlvl = lvlamt * numlvl
        # For the organization's report, count full value for all
        report[ORGS_REPORT][org][lvl] = amtlvl
        orgtotal += amtlvl
        # For the sponsor's report, discount inkind levels
        if ary.is_a?(Array) # Ignore dates or errors
          ary.each do | sponsorurl |
            # TODO somehow mark amountvaries levels?
            lvlamt = (lvlamt * INKIND_DISCOUNT).round(0) if /inkind/.match(lvl)
            # report['sponsortotal'][sponsorurl] += lvlamt # HACK1 this line randomly throws: undefined method `+' for nil:NilClass
            # HACK1 sum up values the hard way
            val = report[SPONSORS_REPORT].fetch(sponsorurl, nil)
            if val
              report[SPONSORS_REPORT][sponsorurl] += lvlamt
            else
              report[SPONSORS_REPORT][sponsorurl] = lvlamt
            end
          end
        end
      end
      report[ORGS_REPORT][org][TOTALS] = orgtotal
    end
    report[SPONSORS_REPORT] = Hash[report[SPONSORS_REPORT].sort_by { |k, v| -v }]
    return report
  end

  # Rough count of number of times different urls appear at levels per org
  # @param sponsors hash returned from scrape_bycss or parse_landscape
  # @return hash of counts of how often domain names appear
  def report_counts(sponsors)
    counts = {}
    counts[ORGS_REPORT] = {}
    counts['all'] = Hash.new(0)
    SponsorUtils::SPONSOR_METALEVELS.each do | lvl |
      counts[lvl] = Hash.new(0)
    end
    sponsors.each do | org, sponsorhash |
      counts[ORGS_REPORT][org] = {}
      if sponsorhash.is_a?(Hash) # Ignore dates or possible error entries
        sponsorhash.each do | level, ary |
          if ary.is_a?(Array)  # Ignore dates or possible error entries
            counts[ORGS_REPORT][org][level] = ary.size
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

  # Get a list of all sponsorship levels/amounts files
  # @param dir pointing to _sponsorships
  # @return hash of org => yaml frontmatter hash
  def get_levels(dir)
    levels = {}
    Dir.glob(File.join(dir, '*.md')) do |file|
      levels[File.basename(file, '.md')] = YAML.load_file(file)
    end
    return levels
  end

  # Get a list of all actual parsed sponsorships
  # @param dir pointing to _data/sponsorships
  # @return hash of org => json hash
  def get_sponsors(dir)
    orgs = {}
    Dir.glob(File.join(dir, '*.json')) do |file|
      next if /-/.match?(file) # Skip files with - dash, which are reports of some kind
      orgs[File.basename(file, '.json')] = JSON.parse(File.read(file))
    end
    return orgs
  end

  # Simplistic report of counts by level, org, etc.
  def report_all_counts()
    allsponsorships = JSON.parse(File.read('_data/allsponsorships.json'))
    report = {}
    allsponsorships.each do | id, hash |
    end

  end

  # ### #### ##### ######
  # Main method for command line use
  if __FILE__ == $PROGRAM_NAME
    sponsorships_dir = '_data/sponsorships'
    sponsors = get_sponsors(sponsorships_dir)
    report = report_counts(sponsors)
    File.open(File.join(sponsorships_dir, 'sponsor-counts.json'), "w") do |f|
      f.write(JSON.pretty_generate(report))
    end
    report = report_funding(sponsors)
    File.open(File.join(sponsorships_dir, 'org-funding.json'), "w") do |f|
      f.write(JSON.pretty_generate(report))
    end
  end
end
