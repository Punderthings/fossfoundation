# frozen_string_literal: true
# SPDX-License-Identifier: Apache-2.0

# Unit tests for SponsorArchive; no network access needed (git uses a local repository).
# Run from project root: ruby assets/ruby/test/sponsor_archive_test.rb
require 'minitest/autorun'
require 'minitest/mock'
require 'tmpdir'
require 'fileutils'
require 'open3'
require_relative '../sponsor_archive'

class SponsorArchiveTest < Minitest::Test
  def in_tmp_project
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p([SponsorUtils::SPONSORSHIPS_DIR, SponsorUtils::DEFAULT_OUTDIR])
        yield dir
      end
    end
  end

  def write_model(org, yaml)
    File.write(File.join(SponsorUtils::SPONSORSHIPS_DIR, "#{org}.md"), "---\n#{yaml}---\n")
  end

  def history(org = 'demo') = SponsorUtils.load_history(SponsorUtils.history_path(SponsorUtils::DEFAULT_HISTORY_DIR, org))

  def test_sources_validation
    assert_equal [], SponsorArchive.sources({})
    ok = SponsorArchive.sources('sources' => [{ 'kind' => 'git', 'repo' => 'r', 'path' => 'p', 'from' => '2019-01-01', 'until' => 20201231 }])
    assert_equal({ 'kind' => 'git', 'repo' => 'r', 'path' => 'p', 'from' => '20190101', 'until' => '20201231' }, ok.first)
    wayback = SponsorArchive.sources('sources' => [{ 'kind' => 'wayback', 'url' => 'https://example.org/sponsors' }]).first
    assert_equal ['https://example.org/sponsors'], wayback['urls'], 'a single url is accepted'
    [
      { 'sources' => { 'kind' => 'git' } },
      { 'sources' => ['git'] },
      { 'sources' => [{ 'kind' => 'ftp', 'url' => 'u' }] },
      { 'sources' => [{ 'kind' => 'wayback' }] },
      { 'sources' => [{ 'kind' => 'git', 'repo' => 'r' }] },
      { 'sources' => [{ 'kind' => 'wiki', 'api' => 'a' }] },
      { 'sources' => [{ 'kind' => 'yearly-page', 'url' => 'https://example.org/donors.html' }] },
      { 'sources' => [{ 'kind' => 'git', 'repo' => 'r', 'path' => 'p', 'from' => 'soon' }] }
    ].each { |model| assert_raises(SponsorUtils::ParseError, model.inspect) { SponsorArchive.sources(model) } }
  end

  MODEL = {
    'identifier' => 'demo', 'landscape' => 'Members', 'effectiveDate' => '20250101',
    'levels' => { 'first' => { 'name' => 'Gold', 'amount' => '10', 'selector' => 'a.gold', 'attr' => 'href' },
                  'second' => { 'name' => 'Silver', 'amount' => '5' } },
    'pastModels' => [{ 'effectiveDate' => '20200101', 'levels' => { 'first' => { 'amount' => '8' } } }],
    'sources' => [{ 'kind' => 'git', 'repo' => 'r', 'path' => 'p' }]
  }.freeze

  def test_source_model_overlays
    source = { 'kind' => 'git', 'repo' => 'r', 'path' => 'p', 'until' => '20201231', 'landscape' => %w[Old Members],
               'levels' => { 'first' => { 'match' => %w[Gold Premium] }, 'second' => nil } }
    config = SponsorArchive.source_model(MODEL, source, '20200601')
    assert_equal %w[Old Members], config['landscape']
    assert_equal({ 'name' => 'Gold', 'amount' => '8', 'selector' => 'a.gold', 'attr' => 'href', 'match' => %w[Gold Premium] }, config['levels']['first'])
    refute config['levels'].key?('second'), 'null removes a level'
    refute config.key?('sources')
    %w[kind repo path until].each { |key| refute config.key?(key), key }
    assert_equal '10', MODEL['levels']['first']['amount'], 'model is not modified'

    listed = SponsorArchive.source_model(MODEL, source.merge('replaceLevels' => true, 'levels' => { 'listed' => { 'selector' => 'a' } }), '20260101')
    assert_equal({ 'listed' => { 'selector' => 'a' } }, listed['levels'])
  end

  def test_monthly_keeps_last_version_per_month_in_range
    v = ->(date) { SponsorArchive::Version.new(date: date, checked: date, ref: date, loader: nil) }
    versions = %w[20190105 20190120 20190301 20190331 20190402 20200115].map(&v).shuffle
    assert_equal %w[20190120 20190331 20190402], SponsorArchive.monthly(versions, '20190101', '20191231').map(&:date)
    assert_equal %w[20190120 20190331 20190402 20200115], SponsorArchive.monthly(versions, nil, nil).map(&:date)
  end

  LANDSCAPE = <<~YAML
    landscape:
      - category:
        name: %<category>s
        subcategories:
          - subcategory:
            name: Gold
            items:
    %<gold>s
          - subcategory:
            name: Silver
            items:
    %<silver>s
  YAML

  def landscape_yaml(category, gold, silver)
    item = ->(host) { "          - item:\n            name: #{host}\n            homepage_url: https://www.#{host}/\n" }
    format(LANDSCAPE, category: category, gold: gold.map(&item).join.chomp, silver: silver.map(&item).join.chomp)
  end

  def git!(dir, *args, date: nil)
    env = date ? { 'GIT_AUTHOR_DATE' => "#{date}T12:00:00Z", 'GIT_COMMITTER_DATE' => "#{date}T12:00:00Z" } : {}
    out, status = Open3.capture2e(env, 'git', '-C', dir, '-c', 'user.name=Test', '-c', 'user.email=test@example.org',
                                  '-c', 'commit.gpgsign=false', *args)
    assert status.success?, out
  end

  def commit(dir, content, date)
    File.write(File.join(dir, 'landscape.yml'), content)
    git!(dir, 'add', 'landscape.yml')
    git!(dir, 'commit', '-q', '--no-verify', '-m', "update #{date}", date: date)
  end

  def test_collect_from_git_repository
    in_tmp_project do |project|
      repo = File.join(project, 'upstream')
      FileUtils.mkdir_p(repo)
      git!(repo, 'init', '-q')
      git!(repo, 'config', 'uploadpack.allowfilter', 'true')
      silver = (1..10).map { |i| "s#{i}.com" }
      commit(repo, landscape_yaml('Other Things', %w[x.com], %w[y.com]), '2019-01-10')        # forked content: rejected
      commit(repo, landscape_yaml('Old Members', %w[a.com], silver), '2019-02-05')            # earlier name, same month as next
      commit(repo, landscape_yml = landscape_yaml('Old Members', %w[a.com b.com], silver), '2019-02-20')
      commit(repo, landscape_yml + "\n# comment only\n", '2019-03-15')                        # same list: extends lastChecked
      commit(repo, landscape_yaml('Members', %w[a.com], %w[s1.com]), '2019-04-10')            # dip between big lists: rejected
      commit(repo, landscape_yaml('Members', %w[b.com], silver), '2019-05-10')
      write_model('demo', <<~YAML)
        identifier: demo
        landscape: Members
        effectiveDate: '20190501'
        levels:
          first:
            name: Gold
            amount: '100'
          second:
            name: Silver
            amount: '10'
        pastModels:
          - effectiveDate: '20180101'
            levels:
              first:
                amount: '50'
        sources:
          - kind: git
            repo: file://#{repo}
            path: landscape.yml
            landscape: [Members, Old Members]
      YAML
      SponsorUtils.write_history(SponsorUtils.history_path(SponsorUtils::DEFAULT_HISTORY_DIR, 'demo'),
                                 SponsorUtils.build_history('demo', [[{ 'parseDate' => '20190301', 'lastChecked' => '20190301', 'source' => 'git' }, { 'first' => %w[old.com] }]]))

      summary = SponsorArchive.collect('demo', from: '20190101', today: Date.new(2019, 6, 1))
      _source, result = summary[:sources].first
      assert_equal 6, result[:versions]
      assert_equal 5, result[:sampled]
      assert_equal({ 'category not found' => 1, 'dip vs neighboring months' => 1 }, result[:rejected].transform_keys { |k| k.sub(/\A.*: /, '') })
      hist = history
      scrapes = hist['scrapes']
      assert_equal %w[20190220 20190510], scrapes.map { |s| s['parseDate'] }, "this repo's backfilled 20190301 list is replaced"
      assert_equal '20190315', scrapes.first['lastChecked']
      assert_equal %w[archive-git archive-git], scrapes.map { |s| s['source'] }
      assert_equal %w[20180101 20190501], scrapes.map { |s| s['modelDate'] }
      assert_equal '20190601', scrapes.last['lastChecked'], 'the newest commit is still current on the collection date'
      assert_match(%r{\Afile://.*upstream@[0-9a-f]{40}:landscape\.yml\z}, scrapes.first['ref'])
      assert_equal({ 'first' => 2, 'second' => 10 }, scrapes.first['counts'])
      assert_includes hist['spans'], { 'sponsor' => 'a.com', 'level' => 'first', 'firstSeen' => '20190220', 'lastSeen' => '20190315' }
      assert File.directory?(File.join(SponsorArchive::CACHE_DIR, 'git')), 'repository is cached'

      again = SponsorArchive.collect('demo', from: '20190101', today: Date.new(2019, 6, 1))
      assert_equal 2, again[:lists], 'collecting again replaces the earlier archive lists'
    end
  end

  def test_collect_dry_run_does_not_write
    in_tmp_project do
      write_model('demo', "identifier: demo\nlevels:\n  first:\n    selector: a\n    attr: href\n" \
                          "sources:\n  - kind: yearly-page\n    url: https://example.org/donors-{year}.html\n")
      SponsorArchive.stub(:http_get, ->(_url, **) { '<html><body><a href="https://a.com/">A</a></body></html>' }) do
        summary = SponsorArchive.collect('demo', from: '20240101', dry_run: true, today: Date.new(2025, 3, 1))
        assert_equal 1, summary[:archive_lists]
      end
      refute File.exist?(SponsorUtils.history_path(SponsorUtils::DEFAULT_HISTORY_DIR, 'demo'))
    end
  end

  def test_wiki_versions_paginate_and_load
    pages = {
      nil => { 'continue' => { 'rvcontinue' => 'next' }, 'query' => { 'pages' => [{ 'revisions' => [{ 'revid' => 3, 'timestamp' => '2019-05-02T10:00:00Z' }] }] } },
      'next' => { 'query' => { 'pages' => [{ 'revisions' => [{ 'revid' => 1, 'timestamp' => '2018-01-09T10:00:00Z' }] }] } }
    }
    requested = []
    fake = lambda do |url, **|
      requested << url
      if url.include?('action=parse')
        JSON.generate('parse' => { 'text' => "<p>rev #{url[/oldid=(\d+)/, 1]}</p>" })
      else
        JSON.generate(pages[url[/rvcontinue=(\w+)/, 1]])
      end
    end
    SponsorArchive.stub(:http_get, fake) do
      versions = SponsorArchive.wiki_versions('api' => 'https://wiki.example/w/api.php', 'title' => 'Corporate Members')
      assert_equal %w[20190502 20180109], versions.map(&:date)
      assert_equal 'https://wiki.example/w/index.php?title=Corporate+Members&oldid=3', versions.first.ref
      assert_equal '<html><body><p>rev 1</p></body></html>', versions.last.loader.call
    end
    assert_equal 3, requested.size
  end

  def test_wiki_missing_page
    SponsorArchive.stub(:http_get, ->(_url, **) { JSON.generate('query' => { 'pages' => [{ 'missing' => true }] }) }) do
      assert_raises(SponsorUtils::ParseError) { SponsorArchive.wiki_versions('api' => 'https://w/api.php', 'title' => 'Nope') }
    end
  end

  def test_yearly_pages_cover_each_year
    in_tmp_project do
      write_model('demo', <<~YAML)
        identifier: demo
        normalize: 'true'
        levels:
          first:
            selector: div.gold a
            attr: href
        sources:
          - kind: yearly-page
            url: https://example.org/donors-{year}.html
            from: '20220101'
      YAML
      cached = {}
      fake = lambda do |url, cache: true|
        cached[url] = cache
        raise SponsorUtils::ParseError, "fetch(#{url}): 404 Not Found" if url.include?('2023')
        year = url[/\d{4}/]
        %(<html><body><div class="gold"><a href="https://www.y#{year}.com/">x</a><a href="https://www.all.com/">a</a></div></body></html>)
      end
      SponsorArchive.stub(:http_get, fake) do
        summary = SponsorArchive.collect('demo', from: '20160101', today: Date.new(2025, 3, 1))
        _source, result = summary[:sources].first
        assert_equal({ '404 Not Found' => 1 }, result[:rejected])
      end
      assert_equal({ 'https://example.org/donors-2022.html' => true, 'https://example.org/donors-2023.html' => true,
                     'https://example.org/donors-2024.html' => true, 'https://example.org/donors-2025.html' => false }, cached)
      scrapes = history['scrapes']
      # 2023 is missing, so 2022's list is confirmed only through 2022
      assert_equal [%w[20220101 20221231], %w[20240101 20241231], %w[20250101 20250301]], scrapes.map { |s| s.values_at('parseDate', 'lastChecked') }
      assert_equal 'https://example.org/donors-2022.html', scrapes.first['ref']
    end
  end

  def entry(date, source, sponsors, checked = date)
    [{ 'parseDate' => date, 'lastChecked' => checked, 'source' => source }, { 'first' => sponsors }]
  end

  def test_merge_entries_precedence
    existing = [
      entry('20180101', 'git', %w[a.com]),
      entry('20190301', 'git', %w[b.com]),
      entry('20190601', 'archive-git', %w[stale.com]),
      entry('20260101', 'scrape', %w[e.com], '20260201')
    ]
    archive = [
      entry('20190101', 'archive-wiki', %w[c.com], '20190501'),
      entry('20200101', 'archive-wiki', %w[c.com], '20200301'),
      entry('20210101', 'archive-wiki', %w[d.com], '20270101'),
      entry('20260101', 'archive-wiki', %w[late.com]),
      entry('20260301', 'archive-wiki', %w[later.com])
    ]
    merged = SponsorArchive.merge_entries(existing, archive)
    # lastChecked stays the last confirmed date, clamped to before the next list
    assert_equal [%w[20180101 20180101 git], %w[20190101 20200301 archive-wiki], %w[20210101 20251231 archive-wiki], %w[20260101 20260201 scrape]],
                 merged.map { |meta, _| meta.values_at('parseDate', 'lastChecked', 'source') }
    assert_equal [%w[a.com], %w[c.com], %w[d.com], %w[e.com]], merged.map { |_, state| state['first'] }
  end

  def test_coverage_tags_by_origin
    in_tmp_project do
      hist = SponsorUtils.build_history('demo', [entry('20180601', 'git', %w[a.com], '20190115'), entry('20190601', 'archive-git', %w[b.com]),
                                                 entry('20200601', 'scrape', %w[c.com])])
      SponsorUtils.write_history(SponsorUtils.history_path(SponsorUtils::DEFAULT_HISTORY_DIR, 'demo'), hist)
      table = SponsorArchive.coverage(SponsorUtils::DEFAULT_HISTORY_DIR, %w[demo none], [2018, 2019, 2020, 2021])
      assert_equal({ 'demo' => { 2018 => 'R1', 2019 => 'A1 R1', 2020 => 'L1', 2021 => '' },
                     'none' => { 2018 => '', 2019 => '', 2020 => '', 2021 => '' } }, table)
      out, = capture_io { SponsorArchive.report_coverage(table, [2018, 2019]) }
      assert_match(/demo\s+R1\s+A1 R1/, out)
    end
  end

  # A fake capture index: url => rows of [timestamp, original]
  def fake_cdx(captures, requests = [])
    lambda do |url, **opts|
      requests << [url, opts]
      if url.start_with?(SponsorArchive::CDX_API)
        query = URI.decode_www_form(URI(url).query).to_h
        rows = captures.fetch(query['url'], [])
        rows = rows.select { |ts, _| ts >= query['from'] } if query['from']
        rows = rows.select { |ts, _| ts[0, 8] <= query['to'] } if query['to']
        JSON.generate(rows.empty? ? [] : [%w[timestamp original]] + rows)
      else
        year = url[%r{/web/(\d{4})}, 1]
        %(<html><body><div class="gold"><a href="https://www.y#{year}.example/">x</a><a href="https://www.all.example/">a</a></div></body></html>)
      end
    end
  end

  def test_wayback_versions
    captures = {
      'example.org/sponsors' => [%w[20190115120000 http://example.org/sponsors], %w[20200301000000 https://example.org/sponsors]],
      'example.org/old-sponsors.html' => [%w[20160704000000 http://www.example.org/old-sponsors.html]]
    }
    requests = []
    SponsorArchive.instance_variable_set(:@cdx_results, nil)
    SponsorArchive.stub(:http_get, fake_cdx(captures, requests)) do
      source = SponsorArchive.sources('sources' => [{ 'kind' => 'wayback', 'urls' => %w[https://example.org/sponsors https://example.org/old-sponsors.html] }]).first
      versions = SponsorArchive.wayback_versions(source, '20170101', nil)
      assert_equal %w[20190115 20200301], versions.map(&:date), 'from limits captures'
      assert_equal 'https://web.archive.org/web/20190115120000id_/http://example.org/sponsors', versions.first.ref
      assert_match(/y2019\.example/, versions.first.loader.call)
      cdx_request = requests.find { |url, _| url.start_with?(SponsorArchive::CDX_API) }
      assert_equal({ cache: false, read_timeout: SponsorArchive::CDX_TIMEOUT }, cdx_request[1])
      assert_includes cdx_request[0], 'collapse=timestamp%3A6'
      assert_equal [], SponsorArchive.wayback_versions(source.merge('urls' => ['https://example.org/none']), nil, nil)
    end
  ensure
    SponsorArchive.instance_variable_set(:@cdx_results, nil)
  end

  def test_cdx_retries_then_reuses_results
    calls = 0
    flaky = lambda do |_url, **|
      calls += 1
      raise SponsorUtils::ParseError, 'fetch: 503 Service Unavailable' if calls == 1
      JSON.generate([%w[timestamp original], %w[20200101000000 http://a.example/]])
    end
    SponsorArchive.instance_variable_set(:@cdx_results, nil)
    waits = []
    SponsorArchive.stub(:http_get, flaky) do
      SponsorArchive.stub(:sleep, ->(seconds) { waits << seconds }) do
        2.times { assert_equal [{ 'timestamp' => '20200101000000', 'original' => 'http://a.example/' }], SponsorArchive.cdx(url: 'a.example') }
      end
    end
    assert_equal 2, calls, 'one retry, then the result is reused'
    assert_equal [15], waits
    SponsorArchive.instance_variable_set(:@cdx_results, nil)
    SponsorArchive.stub(:http_get, ->(_url, **) { raise SponsorUtils::ParseError, 'down' }) do
      SponsorArchive.stub(:sleep, nil) do
        assert_raises(SponsorUtils::ParseError) { SponsorArchive.cdx(url: 'b.example') }
      end
    end
  ensure
    SponsorArchive.instance_variable_set(:@cdx_results, nil)
  end

  def test_collect_wayback_and_keep_history_when_a_source_fails
    in_tmp_project do
      write_model('demo', <<~YAML)
        identifier: demo
        normalize: 'true'
        levels:
          first:
            selector: div.gold a
            attr: href
        sources:
          - kind: wayback
            urls: [https://example.org/sponsors]
      YAML
      captures = { 'example.org/sponsors' => [%w[20190115120000 https://example.org/sponsors], %w[20200301000000 https://example.org/sponsors]] }
      SponsorArchive.instance_variable_set(:@cdx_results, nil)
      SponsorArchive.stub(:http_get, fake_cdx(captures)) do
        summary = SponsorArchive.collect('demo', from: '20160101', today: Date.new(2026, 1, 1))
        assert_empty summary[:errors]
      end
      scrapes = history['scrapes']
      assert_equal [%w[20190115 20190115 archive-wayback], %w[20200301 20200301 archive-wayback]],
                   scrapes.map { |s| s.values_at('parseDate', 'lastChecked', 'source') }, 'archive captures are not confirmed as current'
      before = File.read(SponsorUtils.history_path(SponsorUtils::DEFAULT_HISTORY_DIR, 'demo'))

      SponsorArchive.instance_variable_set(:@cdx_results, nil)
      SponsorArchive.stub(:http_get, ->(_url, **) { raise SponsorUtils::ParseError, 'fetch: 503' }) do
        SponsorArchive.stub(:sleep, nil) do
          out, = capture_io { assert_equal 1, SponsorArchive.main(%w[collect demo]) }
          assert_match(/NOT written: a source failed/, out)
          assert_match(/ERROR wayback https:\/\/example.org\/sponsors: .*503/, out)
        end
      end
      assert_equal before, File.read(SponsorUtils.history_path(SponsorUtils::DEFAULT_HISTORY_DIR, 'demo')), 'history is kept'
    end
  ensure
    SponsorArchive.instance_variable_set(:@cdx_results, nil)
  end

  def test_discover_groups_url_variants
    in_tmp_project do
      write_model('demo', "identifier: demo\nsponsorurl: https://www.example.org/sponsors/\nlevelurl: https://raw.githubusercontent.com/x/y/z.yml\nlevels: {}\n")
      rows = [%w[http://example.org:80/sponsors/ 20150101000000], %w[https://www.example.org/sponsors 20160101000000],
              %w[https://example.org/sponsors?lang=de 20160201000000], %w[https://example.org/members 20200101000000],
              %w[https://example.org/sponsors/logo.png 20200101000000]]
      requests = []
      SponsorArchive.stub(:cdx, ->(params) { requests << params; rows.map { |o, t| { 'original' => o, 'timestamp' => t } } }) do
        pages = SponsorArchive.discover('demo')
        assert_equal [{ url: 'https://example.org/sponsors', months: 3, first: '201501', last: '201602', years: { '2015' => 1, '2016' => 2 } },
                      { url: 'https://example.org/members', months: 1, first: '202001', last: '202001', years: { '2020' => 1 } }], pages
        out, = capture_io { SponsorArchive.report_discover('demo', pages, top: 1) }
        assert_match(/3  201501 to 201602  https:\/\/example.org\/sponsors/, out)
        assert_match(/1 more/, out)
      end
      assert_equal ['example.org'], requests.map { |params| params[:url] }, 'raw.githubusercontent.com is not searched'
      assert_equal 'domain', requests.first[:matchType]
    end
  end

  def test_main_commands
    in_tmp_project do
      write_model('demo', "identifier: demo\nnormalize: 'true'\nlevels:\n  first:\n    selector: a\n    attr: href\n" \
                          "sources:\n  - kind: yearly-page\n    url: https://example.org/donors-{year}.html\n")
      write_model('plain', "identifier: plain\nlevels: {}\n")
      SponsorArchive.stub(:http_get, ->(_url, **) { '<html><body><a href="https://www.a.com/">A</a></body></html>' }) do
        out, = capture_io { assert_equal 0, SponsorArchive.main(%w[preview demo --at 20240601]) }
        assert_match(%r{version 20240101: https://example.org/donors-2024.html}, out)
        assert_match(/first: 1 \["a.com"\]/, out)
        out, = capture_io { assert_equal 0, SponsorArchive.main(%w[collect --from 20250101 --dry-run]) }
        assert_match(/demo: \d+ archive lists .* \(dry run, not written\)/, out)
        refute_match(/plain/, out, 'orgs without sources are skipped')
      end
      out, = capture_io { assert_equal 0, SponsorArchive.main(%w[coverage demo]) }
      assert_match(/^demo\s+-/, out)
      _, err = capture_io { assert_equal 1, SponsorArchive.main(%w[preview ../x]) }
      assert_match(/invalid org id/, err)
      assert_raises(SystemExit) { capture_io { SponsorArchive.main(%w[unknown]) } }
      capture_io { assert_equal 0, SponsorArchive.main(%w[coverage demo --bridge-days 10]) }
      assert_equal 10, SponsorUtils.bridge_days
    ensure
      SponsorUtils.bridge_days = nil
    end
  end
end
