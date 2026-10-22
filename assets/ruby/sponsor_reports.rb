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
  INCOME_DAY = '0701' # Yearly sponsorship income uses the list in effect on this day (MMDD)
  INCOME_MAX_AGE = 366 # days; a list last confirmed longer ago than this before that day is too stale to use

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

  # Estimate yearly sponsorship income per program from its history: for each year, the
  # sponsor list in effect on July 1, priced with the sponsorship model in effect that day.
  # A year is left out when no list was confirmed within INCOME_MAX_AGE days of that day.
  # Lists recorded only at levels without a price (such as 'listed') have a nil estimate.
  # @param history_dir pointing to history/sponsorships
  # @param sponsors optional current data (org => json hash); its lastChecked extends the latest list
  # @param today date, so the current year is included only once its July 1 has passed
  # @return hash of org => [{'year' => YYYY, 'estimate' => USD or nil, 'sponsors' => count}], newest year first
  def report_income(history_dir, sponsors = {}, today: Date.today)
    report = {}
    Dir.glob(File.join(history_dir, '*.json')).sort.each do |file|
      hist = SponsorUtils.load_history(file)
      org = hist['org'] || File.basename(file, '.json')
      model = begin
        SponsorUtils.get_sponsorship_file(org)
      rescue SponsorUtils::ParseError
        next
      end
      scrapes = hist['scrapes'].sort_by { |scrape| scrape['parseDate'] }
      next if scrapes.empty?
      latest_checked = [scrapes.last['lastChecked'], SponsorUtils.date_key(sponsors.dig(org, SponsorUtils::LAST_CHECKED))].compact.max
      years = {}
      (scrapes.first['parseDate'][0, 4].to_i..today.year).each do |year|
        day = "#{year}#{INCOME_DAY}"
        next if day > today.strftime('%Y%m%d')
        index = scrapes.rindex { |scrape| scrape['parseDate'] <= day }
        next unless index
        scrape = scrapes[index]
        checked = index == scrapes.size - 1 ? latest_checked : scrape['lastChecked']
        next if SponsorUtils.days_between(checked || scrape['parseDate'], day) > INCOME_MAX_AGE
        levels = SponsorUtils.model_at(model, day).fetch('levels', {})
        counts = scrape.fetch('counts', {})
        priced = counts.select { |lvl, _n| lvl != 'listed' && levels.key?(lvl) }
        estimate = priced.empty? ? nil : priced.sum { |lvl, n| levels[lvl].fetch('amount', 0).to_i * n }
        years[year.to_s] = [estimate, counts.values.sum]
      end
      report[org] = years.sort.reverse.map { |year, (estimate, count)| { 'year' => year.to_i, 'estimate' => estimate, 'sponsors' => count } } unless years.empty?
    end
    return report
  end

  # Summarize sponsor history files for the website: per org, one row per scrape
  # with sponsor counts and an estimated total using the amounts in effect then
  # @param history_dir pointing to history/sponsorships
  # @param sponsors optional current data (org => json hash); its lastChecked extends the latest row
  # @return hash of org => [{parseDate, lastChecked, sponsors, levels, estimate}]
  def report_history(history_dir, sponsors = {})
    report = {}
    Dir.glob(File.join(history_dir, '*.json')).sort.each do |file|
      hist = SponsorUtils.load_history(file)
      org = hist['org'] || File.basename(file, '.json')
      model = begin
        SponsorUtils.get_sponsorship_file(org)
      rescue SponsorUtils::ParseError
        nil
      end
      rows = hist['scrapes'].sort_by { |scrape| scrape['parseDate'] }.map do |scrape|
        counts = scrape.fetch('counts', {})
        estimate = nil
        if model
          levels = SponsorUtils.model_at(model, scrape['parseDate']).fetch('levels', {})
          estimate = counts.sum { |lvl, n| levels.fetch(lvl, {}).fetch('amount', 0).to_i * n }
        end
        { 'parseDate' => scrape['parseDate'], 'lastChecked' => scrape['lastChecked'],
          'sponsors' => counts.values.sum, 'levels' => counts, 'estimate' => estimate }
      end
      current_checked = SponsorUtils.date_key(sponsors.dig(org, SponsorUtils::LAST_CHECKED))
      if rows.any? && current_checked && current_checked > rows.last['lastChecked'].to_s
        rows.last['lastChecked'] = current_checked
      end
      report[org] = rows
    end
    return report
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
    if Dir.exist?(SponsorUtils::DEFAULT_HISTORY_DIR)
      File.write(File.join(outdir, 'sponsor-history.json'),
                 JSON.pretty_generate(report_history(SponsorUtils::DEFAULT_HISTORY_DIR, sponsors)))
      File.write(File.join(outdir, 'sponsor-income.json'),
                 JSON.pretty_generate(report_income(SponsorUtils::DEFAULT_HISTORY_DIR, sponsors)))
    end
  end
end
