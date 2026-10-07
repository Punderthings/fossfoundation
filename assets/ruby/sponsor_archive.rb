#!/usr/bin/env ruby
# frozen_string_literal: true
# SPDX-License-Identifier: Apache-2.0

require_relative 'sponsor_utils'

module SponsorArchive
  DESCRIPTION = <<-HEREDOC
  SponsorArchive: best-effort collection of historical sponsor lists.
    Run from project root.  Reads the 'sources:' list in each
    _sponsorships/<org>.md, finds past versions of each source, keeps the
    last version per month, parses each with that source's settings, and
    merges the lists into history/sponsorships/<org>.json with provenance.

    Commands:
      collect [ORG...]          Collect history for orgs with sources (default: all)
      discover ORG              List archived pages on the org's sites that look like sponsor lists
      preview ORG --at DATE     Show what each source parses to on DATE
      coverage [ORG...]         Table of recorded lists per year, by origin

    Source kinds (see _data/sponsorships-schema.json):
      git          Versions of a file in a git repository (partial clone, cached)
      wiki         Revisions of a MediaWiki page, rendered by the wiki's API
      yearly-page  A page published per year, url with {year}
      wayback      Internet Archive captures of one or more page URLs (urls:),
                   fetched raw (id_) so links are the original sponsor links

    Precedence when merging: live scrapes (sponsor_utils.rb) win from the
    date they start; archive lists replace this repository's own backfilled
    lists for the period the archive covers.  A sponsor missing for at most
    --bridge-days (default 31, one monthly sample) keeps one continuous span.
    Raw content is cached in
    .cache/sponsor-archive; only parsed lists and their 'ref' are kept.
  HEREDOC
  module_function
  require 'json'
  require 'date'
  require 'digest'
  require 'fileutils'
  require 'open3'
  require 'optparse'
  require 'stringio'
  require 'uri'

  ParseError = SponsorUtils::ParseError
  CACHE_DIR = '.cache/sponsor-archive'
  SOURCE_KINDS = %w[git wiki yearly-page wayback].freeze
  # Source keys that describe where versions come from; all other keys override the model
  LOCATION_KEYS = %w[kind repo path branch api title url urls from until replaceLevels].freeze
  CDX_API = 'https://web.archive.org/cdx/search/cdx'
  WAYBACK = 'https://web.archive.org/web'
  CDX_TIMEOUT = 180 # seconds; the capture index is often slow
  CDX_RETRY_WAITS = [15, 45].freeze # seconds before retrying a failed capture index query
  DISCOVER_WORDS = 'sponsor|member|partner|donor|donat|support|thank|funding|join|benefactor|patron'
  DEFAULT_FROM = '20160101'
  REQUEST_DELAY = 1.0 # seconds between network requests to one wiki or site
  WAYBACK_DELAY = 4.0 # seconds between requests to web.archive.org, which refuses faster clients
  DIP_RATIO = 0.5 # a list smaller than this fraction of both neighbors is treated as a bad parse
  LIVE_SOURCES = %w[scrape manual].freeze
  ARCHIVE_PREFIX = 'archive-'

  # One available version of a sponsor list: dated, with provenance and a way to load it
  Version = Data.define(:date, :checked, :ref, :loader)

  # ## ### #### ##### ######
  # Sources and per-source models

  # @return validated array of source hashes from a model's 'sources' list
  # @raise ParseError on unknown kinds or missing fields
  def sources(model)
    list = model['sources'] || []
    raise ParseError, 'sources must be a list' unless list.is_a?(Array)
    list.each_with_index.map do |source, i|
      raise ParseError, "sources[#{i}] must be a hash" unless source.is_a?(Hash)
      kind = source['kind']
      raise ParseError, "sources[#{i}]: unknown kind '#{kind}' (expected #{SOURCE_KINDS.join(', ')})" unless SOURCE_KINDS.include?(kind)
      required = { 'git' => %w[repo path], 'wiki' => %w[api title], 'yearly-page' => %w[url], 'wayback' => %w[urls] }.fetch(kind)
      if kind == 'wayback'
        source = source.merge('urls' => Array(source['urls'] || source['url']).map(&:to_s).reject(&:empty?))
        raise ParseError, "sources[#{i}] (wayback) needs urls" if source['urls'].empty?
      end
      missing = required.reject { |key| source[key].to_s.strip != '' }
      raise ParseError, "sources[#{i}] (#{kind}) needs #{missing.join(', ')}" unless missing.empty?
      raise ParseError, "sources[#{i}]: url needs {year}" if kind == 'yearly-page' && !source['url'].include?('{year}')
      source.merge('from' => SponsorUtils.date_key(source['from']), 'until' => SponsorUtils.date_key(source['until']))
    end
  end

  # The model to parse one source's version with: the model in effect on that date,
  # overlaid with the source's own settings (any key but its location keys).  Levels
  # merge per level (null removes one) unless replaceLevels is true.
  # @return model hash
  def source_model(model, source, date)
    base = SponsorUtils.model_at(model, date).reject { |key, _| key == 'sources' }
    result = Marshal.load(Marshal.dump(base))
    source.each { |key, value| result[key] = value unless LOCATION_KEYS.include?(key) || key == 'levels' }
    overrides = source['levels'] || {}
    if SponsorUtils.as_bool(source['replaceLevels'])
      result['levels'] = Marshal.load(Marshal.dump(overrides))
    else
      levels = (result['levels'] ||= {})
      overrides.each do |lvl, fields|
        fields.nil? ? levels.delete(lvl) : levels[lvl] = (levels[lvl] || {}).merge(fields)
      end
    end
    return result
  end

  # @return versions within [from, until], keeping the last version of each month, oldest first
  def monthly(versions, from, until_date)
    in_range = versions.select { |v| (from.nil? || v.date >= from) && (until_date.nil? || v.date <= until_date) }
    in_range.group_by { |v| v.date[0, 6] }.map { |_month, list| list.max_by(&:date) }.sort_by(&:date)
  end

  # ## ### #### ##### ######
  # Fetching, with a cache

  # @return cache path for a key
  def cache_path(*parts)
    File.join(CACHE_DIR, *parts)
  end

  # GET a url politely, caching the body when cache is true
  # @return body string
  # @raise ParseError on fetch failures
  def http_get(url, cache: true, read_timeout: SponsorUtils::READ_TIMEOUT)
    path = cache_path('http', Digest::SHA256.hexdigest(url))
    return File.binread(path) if cache && File.file?(path)
    host = URI.parse(url).host.to_s
    @last_request ||= {}
    delay = host == 'web.archive.org' ? WAYBACK_DELAY : REQUEST_DELAY
    wait = delay - (Process.clock_gettime(Process::CLOCK_MONOTONIC) - @last_request.fetch(host, 0))
    sleep(wait) if wait.positive?
    begin
      body = SponsorUtils.fetch(url, read_timeout: read_timeout)
    ensure
      @last_request[host] = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
    if cache
      FileUtils.mkdir_p(File.dirname(path))
      File.binwrite(path, body)
    end
    return body
  end

  # Run git, returning stdout; retries once, since partial clones fetch file contents on demand
  # @raise ParseError if git fails
  def git(*args)
    err = nil
    2.times do
      out, err, status = Open3.capture3('git', *args, binmode: true)
      return out if status.success?
    end
    command = args.first == '-C' ? args.drop(2) : args
    raise ParseError, "git #{command.first(2).join(' ')}: #{err.to_s.strip.lines.last.to_s.strip}"
  end

  # @return local partial clone of a repository, cloned or updated once per run
  def git_checkout(repo)
    dir = cache_path('git', repo.sub(%r{\A\w+://}, '').sub(/\.git\z/, '').gsub(/[^\w.-]+/, '_'))
    @updated_repos ||= {}
    return dir if @updated_repos[dir]
    if File.directory?(File.join(dir, '.git')) || File.file?(File.join(dir, 'HEAD'))
      git('-C', dir, 'fetch', '--quiet', '--filter=blob:none', 'origin')
    else
      FileUtils.mkdir_p(File.dirname(dir))
      git('clone', '--quiet', '--filter=blob:none', '--no-checkout', repo, dir)
    end
    @updated_repos[dir] = true
    return dir
  end

  # ## ### #### ##### ######
  # Versions available from each kind of source

  # Versions of a file in git, following renames
  def git_versions(source)
    dir = git_checkout(source['repo'])
    ref = source['branch'] ? "origin/#{source['branch']}" : 'origin/HEAD'
    log = git('-C', dir, 'log', ref, '--follow', "--format=%x01%H %cs", '--name-only', '--', source['path'])
    log.force_encoding('UTF-8').split("\x01").filter_map do |chunk|
      head, *names = chunk.strip.lines.map(&:strip).reject(&:empty?)
      next unless head
      sha, day = head.split
      file = names.first || source['path']
      date = day.delete('-')
      Version.new(date: date, checked: date, ref: "#{source['repo']}@#{sha}:#{file}",
                  loader: -> { git('-C', dir, 'show', "#{sha}:#{file}").force_encoding('UTF-8').scrub })
    end
  end

  # Revisions of a MediaWiki page
  def wiki_versions(source)
    api = source['api']
    index = api.sub(/api\.php\z/, 'index.php')
    revisions = []
    params = { action: 'query', prop: 'revisions', titles: source['title'], rvlimit: 'max', rvprop: 'ids|timestamp', format: 'json', formatversion: 2 }
    loop do
      data = JSON.parse(http_get("#{api}?#{URI.encode_www_form(params)}", cache: false))
      page = data.dig('query', 'pages', 0) || {}
      raise ParseError, "wiki #{source['title']}: page not found" if page['missing']
      revisions.concat(page['revisions'] || [])
      break unless (cont = data.dig('continue', 'rvcontinue'))
      params[:rvcontinue] = cont
    end
    revisions.map do |rev|
      id = rev['revid']
      date = rev['timestamp'][0, 10].delete('-')
      url = "#{api}?#{URI.encode_www_form(action: 'parse', oldid: id, prop: 'text', format: 'json', formatversion: 2)}"
      Version.new(date: date, checked: date, ref: "#{index}?#{URI.encode_www_form(title: source['title'], oldid: id)}",
                  loader: -> { "<html><body>#{JSON.parse(http_get(url)).dig('parse', 'text')}</body></html>" })
    end
  end

  # Pages published per year; each lists the year's sponsors, so it covers Jan 1 - Dec 31
  def yearly_versions(source, from, until_date, today)
    first = ([from, source['from']].compact.max || DEFAULT_FROM)[0, 4].to_i
    last = [until_date, source['until'], today.strftime('%Y%m%d')].compact.min[0, 4].to_i
    (first..last).map do |year|
      url = source['url'].gsub('{year}', year.to_s)
      checked = [format('%04d1231', year), today.strftime('%Y%m%d')].min
      Version.new(date: format('%04d0101', year), checked: checked, ref: url,
                  loader: -> { http_get(url, cache: year < today.year) })
    end
  end

  # Query the Internet Archive capture index
  # @param params CDX query parameters; filter may be a list
  # @return array of row hashes keyed by the requested fields
  # @raise ParseError on failures or unexpected responses
  def cdx(params)
    query = URI.encode_www_form(params.merge(output: 'json').flat_map { |key, value| Array(value).map { |v| [key, v] } })
    @cdx_results ||= {}
    return @cdx_results[query] if @cdx_results.key?(query)
    body = nil
    [0, *CDX_RETRY_WAITS].each_with_index do |wait, attempt|
      sleep(wait) if wait.positive?
      begin
        body = http_get("#{CDX_API}?#{query}", cache: false, read_timeout: CDX_TIMEOUT)
        break
      rescue ParseError
        raise if attempt == CDX_RETRY_WAITS.size
        SponsorUtils.log("capture index query failed; retrying in #{CDX_RETRY_WAITS[attempt]}s")
      end
    end
    rows = JSON.parse(body)
    raise ParseError, 'unexpected capture index response' unless rows.is_a?(Array)
    return @cdx_results[query] = [] if rows.empty?
    fields = rows.first
    return @cdx_results[query] = rows.drop(1).map { |row| fields.zip(row).to_h }
  rescue JSON::ParserError => e
    raise ParseError, "capture index: #{e.message[0, 100]}"
  end

  # Internet Archive captures of a source's URLs, at most one per month per URL
  # Each is loaded raw (id_), so links point at sponsors rather than at the archive.
  def wayback_versions(source, from, until_date)
    Array(source['urls']).flat_map do |url|
      params = { url: url.sub(%r{\Ahttps?://}, ''), fl: 'timestamp,original', filter: 'statuscode:200', collapse: 'timestamp:6' }
      params[:from] = from if from
      params[:to] = until_date if until_date
      cdx(params).map do |row|
        ref = "#{WAYBACK}/#{row['timestamp']}id_/#{row['original']}"
        date = row['timestamp'][0, 8]
        Version.new(date: date, checked: date, ref: ref, loader: -> { http_get(ref) })
      end
    end
  end

  # Find archived pages on an org's sites whose URLs look like sponsor or member lists
  # @return array of {url:, months:, first:, last:, years: {year => months}} sorted by months, most first
  def discover(org, limit: 20_000)
    model = SponsorUtils.get_sponsorship_file(org)
    urls = [model['sponsorurl'], model['levelurl']] + sources(model).flat_map { |source| Array(source['urls'] || source['url']) }
    hosts = urls.compact.filter_map { |url| URI.parse(url).host rescue nil }
                .map { |host| host.delete_prefix('www.') }.reject { |host| host.end_with?('githubusercontent.com', 'github.com') }.uniq
    pages = Hash.new { |h, k| h[k] = Set.new }
    hosts.each do |host|
      rows = cdx(url: host, matchType: 'domain', fl: 'original,timestamp', limit: limit,
                 filter: ['statuscode:200', "original:.*(#{DISCOVER_WORDS}).*"], collapse: 'timestamp:6')
      rows.each do |row|
        key = row['original'].sub(%r{\Ahttps?://(www\.)?}, '').sub(%r{\A([^/]+):(?:80|443)(?=/|\z)}, '\1').sub(/[?#].*\z/, '').sub(%r{/\z}, '')
        next if key.match?(/\.(png|jpe?g|gif|svg|css|js|ico|woff2?)\z/i)
        pages[key] << row['timestamp'][0, 6]
      end
    end
    pages.map do |key, months|
      sorted = months.sort
      { url: "https://#{key}", months: sorted.size, first: sorted.first, last: sorted.last,
        years: sorted.group_by { |m| m[0, 4] }.transform_values(&:size) }
    end.sort_by { |page| [-page[:months], page[:url]] }
  end

  # Print discover results
  def report_discover(org, pages, top: 25)
    puts "#{org}: #{pages.size} archived pages with sponsor-like URLs (months captured, first to last)"
    pages.first(top).each do |page|
      puts format('  %3d  %s to %s  %s', page[:months], page[:first], page[:last], page[:url])
    end
    puts "  ... #{pages.size - top} more" if pages.size > top
  end

  # @return all versions a source offers
  def versions_for(source, from: nil, until_date: nil, today: Date.today)
    case source['kind']
    when 'git' then git_versions(source)
    when 'wiki' then wiki_versions(source)
    when 'yearly-page' then yearly_versions(source, from, until_date, today)
    when 'wayback' then wayback_versions(source, from, until_date)
    end
  end

  # ## ### #### ##### ######
  # Parsing and collecting

  # Parse one version with its source's settings
  # @return [state {level => sponsors}, warnings array]
  # @raise ParseError if the version cannot be used
  def parse_version(model, source, version)
    config = source_model(model, source, version.date)
    content = version.loader.call
    warnings = StringIO.new
    original = $stderr
    $stderr = warnings
    begin
      sponsors = case SponsorUtils.source_type(config)
                 when 'landscape' then SponsorUtils.parse_landscape(content, config)
                 when 'landscapejson', 'json', 'yaml' then SponsorUtils.parse_json(content, config)
                 when 'css' then SponsorUtils.scrape_bycss(content, config)
                 else raise ParseError, "sourcetype #{SponsorUtils.source_type(config)} cannot be archived"
                 end
      sponsors = SponsorUtils.cleanup_with_map(sponsors, config['sponsormap']) if config['sponsormap']
    ensure
      $stderr = original
    end
    _date, state = SponsorUtils.version_state(sponsors.merge(SponsorUtils::PARSE_DATE => version.date))
    raise ParseError, 'no sponsors, or two levels list the same sponsors' unless state
    return [state, warnings.string.lines.map(&:strip)]
  end

  # Short reason for a rejected version, for summaries
  def reason(error)
    error.message.sub(/\Aparse_\w+\([^)]*\):\s*/, '').sub(/\Afetch\(\S+\):\s*/, '')[0, 60]
  end

  # Collect one source's lists
  # @return {entries: [[meta, state]], versions:, sampled:, rejected: {reason => count}}
  def collect_source(model, source, from:, until_date:, today: Date.today)
    lower = [from, source['from']].compact.max
    upper = [until_date, source['until']].compact.min
    all = versions_for(source, from: lower, until_date: upper, today: today)
    sampled = monthly(all, lower, upper)
    # The newest git commit or wiki revision is still the current content, so it is confirmed today
    newest = all.max_by(&:date)
    if newest && sampled.last.equal?(newest) && upper.nil? && %w[git wiki].include?(source['kind'])
      sampled[-1] = newest.with(checked: today.strftime('%Y%m%d'))
    end
    rejected = Hash.new(0)
    accepted = sampled.filter_map do |version|
      state, = parse_version(model, source, version)
      [version, state]
    rescue ParseError => e
      rejected[reason(e)] += 1
      nil
    end
    totals = accepted.map { |_v, state| state.values.sum(&:size) }
    dips = (1...accepted.size - 1).select do |i|
      totals[i] < DIP_RATIO * [totals[i - 1], totals[i + 1]].min
    end
    rejected['dip vs neighboring months'] += dips.size unless dips.empty?
    dips.reverse_each { |i| accepted.delete_at(i) }
    entries = []
    accepted.each do |version, state|
      if entries.last && entries.last[1] == state
        entries.last[0]['lastChecked'] = version.checked
        next
      end
      meta = { 'parseDate' => version.date, 'lastChecked' => version.checked, 'source' => "#{ARCHIVE_PREFIX}#{source['kind']}",
               'ref' => version.ref, 'modelDate' => SponsorUtils.date_key(SponsorUtils.model_at(model, version.date)[SponsorUtils::EFFECTIVE_DATE]) }
      entries << [meta.compact, state]
    end
    return { entries: entries, versions: all.size, sampled: sampled.size, rejected: rejected }
  end

  # Merge archive lists into existing history entries
  # Live scrapes win from their first date; archive lists replace this repository's
  # own backfilled lists inside the archive's period; earlier archive runs are replaced.
  # @return merged entries, date ordered, consecutive identical lists combined
  def merge_entries(existing, archive)
    existing = existing.reject { |meta, _| meta['source'].to_s.start_with?(ARCHIVE_PREFIX) }
    live_start = existing.select { |meta, _| LIVE_SOURCES.include?(meta['source']) }.map { |meta, _| meta['parseDate'] }.min
    archive = archive.select { |meta, _| live_start.nil? || meta['parseDate'] < live_start }
    unless archive.empty?
      first = archive.first[0]['parseDate']
      last = archive.map { |meta, _| meta['lastChecked'] }.max
      existing = existing.reject do |meta, _|
        !LIVE_SOURCES.include?(meta['source']) && meta['parseDate'] >= first && meta['parseDate'] <= last
      end
    end
    rank = ->(meta) { LIVE_SOURCES.include?(meta['source']) ? 0 : meta['source'].to_s.start_with?(ARCHIVE_PREFIX) ? 1 : 2 }
    merged = (existing + archive).sort_by { |meta, _| [meta['parseDate'], rank.call(meta)] }
    merged = merged.chunk_while { |a, b| a[0]['parseDate'] == b[0]['parseDate'] }.map(&:first)
    combined = []
    merged.each do |meta, state|
      if combined.last && combined.last[1] == state
        combined.last[0]['lastChecked'] = [combined.last[0]['lastChecked'], meta['lastChecked']].compact.max
        next
      end
      combined << [meta.dup, state]
    end
    combined.each_cons(2) do |(meta, _), (following, _)|
      limit = SponsorUtils.day_before(following['parseDate'])
      meta['lastChecked'] = [[meta['lastChecked'] || meta['parseDate'], limit].min, meta['parseDate']].max
    end
    return combined
  end

  # Collect every source of one org and merge into its history
  # @return summary hash
  def collect(org, from: DEFAULT_FROM, until_date: nil, history_dir: SponsorUtils::DEFAULT_HISTORY_DIR, dry_run: false, today: Date.today)
    model = SponsorUtils.get_sponsorship_file(org)
    results = sources(model).map do |source|
      [source, collect_source(model, source, from: SponsorUtils.date_key(from), until_date: SponsorUtils.date_key(until_date), today: today)]
    rescue ParseError => e
      [source, { entries: [], versions: 0, sampled: 0, rejected: { reason(e) => 1 }, error: e.message }]
    end
    archive = results.flat_map { |_source, result| result[:entries] }
                     .sort_by { |meta, _| meta['parseDate'] }
                     .chunk_while { |a, b| a[0]['parseDate'] == b[0]['parseDate'] }.map(&:first)
    path = SponsorUtils.history_path(history_dir, org)
    hist = SponsorUtils.load_history(path)
    merged = merge_entries(hist ? SponsorUtils.history_states(hist) : [], archive)
    built = SponsorUtils.build_history(org, merged)
    errors = results.filter_map do |source, result|
      "#{source['kind']} #{source['repo'] || source['title'] || Array(source['urls'] || source['url']).first}: #{result[:error]}" if result[:error]
    end
    # A failed source would otherwise drop its earlier archive lists, so leave the history as it is
    SponsorUtils.write_history(path, built) unless dry_run || archive.empty? || errors.any?
    return { org: org, sources: results, archive_lists: archive.size, lists: built['scrapes'].size, spans: built['spans'].size,
             path: path, errors: errors }
  end

  # ## ### #### ##### ######
  # Reports

  # Print a collect summary
  def report_collect(summary, dry_run)
    status = if summary[:errors].any? then ' (NOT written: a source failed)'
             elsif dry_run then ' (dry run, not written)'
             else ''
             end
    puts "#{summary[:org]}: #{summary[:archive_lists]} archive lists -> history has #{summary[:lists]} lists, " \
         "#{summary[:spans]} spans#{status}"
    summary[:errors].each { |error| puts "  ERROR #{error}" }
    summary[:sources].each do |source, result|
      where = source['repo'] || source['title'] || Array(source['urls'] || source['url']).join(' ')
      rejected = result[:rejected].map { |why, n| "#{why}: #{n}" }.join('; ')
      puts "  #{source['kind']} #{where}: #{result[:versions]} versions, #{result[:sampled]} months, " \
           "#{result[:entries].size} lists#{rejected.empty? ? '' : " (rejected #{rejected})"}"
    end
  end

  # Show what each source of an org parses to on a date
  def preview(org, at, source_index: nil, today: Date.today)
    model = SponsorUtils.get_sponsorship_file(org)
    at = SponsorUtils.date_key(at)
    sources(model).each_with_index do |source, i|
      next if source_index && i != source_index
      version = versions_for(source, from: nil, until_date: nil, today: today).select { |v| v.date <= at }.max_by(&:date)
      puts "[#{i}] #{source['kind']} #{source['repo'] || source['title'] || Array(source['urls'] || source['url']).join(' ')}"
      unless version
        puts '    no version on or before that date'
        next
      end
      puts "    version #{version.date}: #{version.ref}"
      if (source['from'] && at < source['from']) || (source['until'] && at > source['until'])
        puts "    note: #{at} is outside this source's dates (#{source['from'] || 'start'} to #{source['until'] || 'now'}); collect will not use it"
      end
      begin
        state, warnings = parse_version(model, source, version)
        state.each { |lvl, sponsors| puts "    #{lvl}: #{sponsors.size} #{sponsors.first(5).inspect}" }
        warnings.first(5).each { |line| puts "    #{line}" }
      rescue ParseError => e
        puts "    rejected: #{e.message}"
      end
    end
  end

  # Count recorded lists per org and year by origin: A archive, L live scrape, R this repo's backfill
  # @return {org => {year => 'A2 R1'}}
  def coverage(history_dir, orgs, years)
    orgs.to_h do |org|
      hist = SponsorUtils.load_history(SponsorUtils.history_path(history_dir, org))
      cells = years.to_h do |year|
        counts = Hash.new(0)
        (hist ? hist['scrapes'] : []).each do |scrape|
          from = scrape['parseDate']
          to = scrape['lastChecked'] || from
          next unless from[0, 4].to_i <= year && to[0, 4].to_i >= year
          tag = LIVE_SOURCES.include?(scrape['source']) ? 'L' : scrape['source'].to_s.start_with?(ARCHIVE_PREFIX) ? 'A' : 'R'
          counts[tag] += 1
        end
        [year, counts.sort.map { |tag, n| "#{tag}#{n}" }.join(' ')]
      end
      [org, cells]
    end
  end

  # Print the coverage table
  def report_coverage(table, years)
    puts format('%-14s %s', 'org', years.map { |y| format('%-7s', y) }.join)
    table.each do |org, cells|
      puts format('%-14s %s', org, years.map { |y| format('%-7s', cells[y].empty? ? '-' : cells[y]) }.join)
    end
    puts 'A = archive lists, L = live scrapes, R = earlier lists from this repository; - = none'
  end

  # ## ### #### ##### ######
  # Command line

  # @return [command, args, options]
  def parse_commandline(argv)
    options = { from: DEFAULT_FROM, history: SponsorUtils::DEFAULT_HISTORY_DIR }
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} collect|preview|coverage|discover [ORG...] [options]"
      opts.on('-h', '--help') { puts "#{DESCRIPTION}\n#{opts}"; exit }
      opts.on('--from DATE', "collect: earliest date (default #{DEFAULT_FROM}).") { |d| options[:from] = d }
      opts.on('--until DATE', 'collect: latest date.') { |d| options[:until] = d }
      opts.on('--at DATE', 'preview: date to show (default today).') { |d| options[:at] = d }
      opts.on('--source N', Integer, 'preview: only the Nth source (from 0).') { |n| options[:source] = n }
      opts.on('--history DIR', "History directory (default #{SponsorUtils::DEFAULT_HISTORY_DIR}).") { |d| options[:history] = d }
      opts.on('-n', '--dry-run', 'collect: report what would be recorded without writing.') { options[:dry_run] = true }
      opts.on('--bridge-days DAYS', Integer, "collect: treat sponsor absences up to DAYS long as continuous (default #{SponsorUtils::DEFAULT_BRIDGE_DAYS}; 0 disables).") do |days|
        options[:bridge_days] = days
      end
      opts.on('-v', '--[no-]verbose', 'Verbose output.') { |v| options[:verbose] = v }
    end
    begin
      args = parser.parse(argv)
    rescue OptionParser::ParseError => e
      warn "#{e.message}\n#{parser}"
      exit 1
    end
    command = args.shift
    unless %w[collect preview coverage discover].include?(command)
      warn parser.banner
      exit 1
    end
    return [command, args, options]
  end

  # @return exit code
  def main(argv = ARGV)
    command, orgs, options = parse_commandline(argv)
    SponsorUtils.verbose = options.fetch(:verbose, false)
    SponsorUtils.bridge_days = options[:bridge_days] if options[:bridge_days]
    orgs.each { |org| raise ParseError, "invalid org id #{org}" unless SponsorUtils::ORG_ID_PATTERN.match?(org) }
    case command
    when 'preview'
      raise ParseError, 'preview needs one ORG' unless orgs.size == 1
      preview(orgs.first, options[:at] || Date.today, source_index: options[:source])
    when 'discover'
      raise ParseError, 'discover needs ORG' if orgs.empty?
      orgs.each { |org| report_discover(org, discover(org)) }
    when 'coverage'
      years = (DEFAULT_FROM[0, 4].to_i..Date.today.year).to_a
      orgs = SponsorUtils.all_org_ids if orgs.empty?
      report_coverage(coverage(options[:history], orgs, years), years)
    when 'collect'
      if orgs.empty?
        orgs = SponsorUtils.all_org_ids.select { |org| sources(SponsorUtils.get_sponsorship_file(org)).any? }
      end
      failures = 0
      orgs.each do |org|
        summary = collect(org, from: options[:from], until_date: options[:until], history_dir: options[:history], dry_run: options[:dry_run])
        report_collect(summary, options[:dry_run])
        failures += 1 if summary[:errors].any?
      rescue ParseError => e
        failures += 1
        warn "ERROR: #{org}: #{e.message}"
      end
      return failures.zero? ? 0 : 1
    end
    return 0
  rescue ParseError => e
    warn "ERROR: #{e.message}"
    return 1
  end

  exit(main) if __FILE__ == $PROGRAM_NAME
end
