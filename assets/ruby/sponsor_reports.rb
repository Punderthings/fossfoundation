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
  # Level amounts are those in effect on each org's parseDate (see SponsorUtils.model_at),
  # or on as_of for every org when given
  # @param allsponsors output of sponsor_utils listing org sponsors scraped
  # @param as_of optional date (YYYYMMDD) whose sponsorship amounts to use
  # @return hash of estimated funding levels by org or sponsor
  def report_funding(allsponsors, as_of: nil)
    alltotal = 0
    report = {}
    report[ORGS_REPORT] = {}
    report[SPONSORS_REPORT] = Hash.new(0)
    allsponsors.each do | org, sponsors |
      orgtotal = 0
      report[ORGS_REPORT][org] = {}
      model = SponsorUtils.get_sponsorship_file(org)
      orglevels = SponsorUtils.model_at(model, as_of || sponsors[SponsorUtils::PARSE_DATE]).fetch('levels', {})
      sponsors.each do | lvl, ary |
        next unless ary.is_a?(Array) # Ignore parseDate, etc.
        lvlamt = orglevels.fetch(lvl, {}).fetch('amount', 0).to_i
        amtlvl = lvlamt * ary.size
        # For the organization's report, count full value for all
        report[ORGS_REPORT][org][lvl] = amtlvl
        orgtotal += amtlvl
        # For the sponsor's report, discount inkind levels
        # TODO somehow mark amountvaries levels?
        sponsoramt = /inkind/.match?(lvl) ? (lvlamt * INKIND_DISCOUNT).round(0) : lvlamt
        ary.each do | sponsorurl |
          report[SPONSORS_REPORT][sponsorurl] += sponsoramt
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
            counts[level] ||= Hash.new(0) # Levels outside SPONSOR_METALEVELS
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
    require 'optparse'
    sponsorships_dir = '_data/sponsorships'
    outdir = sponsorships_dir
    as_of = nil
    OptionParser.new do |opts|
      opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options]\n#{DESCRIPTION}"
      opts.on('--as-of DATE', 'Use sponsorship amounts in effect on DATE (YYYYMMDD) for every org; default is each org      f.write(JSON.pretty_generate(report))
    end
  end
end
s parseDate.') do |date|
        as_of = SponsorUtils.date_key(date)
      end
      opts.on('--out DIR', "Directory to write reports (default #{sponsorships_dir}).") { |dir| outdir = dir }
    end.parse!
    sponsors = get_sponsors(sponsorships_dir)
    report = report_counts(sponsors)
    File.open(File.join(outdir, 'sponsor-counts.json'), "w") do |f|
      f.write(JSON.pretty_generate(report))
    end
    report = report_funding(sponsors, as_of: as_of)
    File.open(File.join(outdir, 'org-funding.json'), "w") do |f|
      f.write(JSON.pretty_generate(report))
    end
  end
end
