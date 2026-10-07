# frozen_string_literal: true

# Unit tests for SponsorUtils and SponsorReports; no network access needed.
# Run from project root: ruby assets/ruby/test/sponsor_utils_test.rb
require 'minitest/autorun'
require 'minitest/mock'
require 'tmpdir'
require 'fileutils'
require 'socket'
require_relative '../sponsor_utils'
require_relative '../sponsor_reports'

# Run a block inside a temporary project root with _sponsorships and _data/sponsorships
module TmpProject
  def in_tmp_project
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p([SponsorUtils::SPONSORSHIPS_DIR, SponsorUtils::DEFAULT_OUTDIR])
        yield dir
      end
    end
  end

  def write_model(org, yaml, body = "\nSome markdown body: with: colons\n---\n")
    File.write(File.join(SponsorUtils::SPONSORSHIPS_DIR, "#{org}.md"), "---\n#{yaml}---\n#{body}")
  end
end

class SponsorUtilsTest < Minitest::Test
  include TmpProject

  HTML = <<~HTML
    <html><body>
      <div id="gold"><a href="https://www.Example.com/About?x=1">Ex</a><a href="https://example.com/dup">Dup</a></div>
      <div id="silver"><a href="https://opensource.google/">G</a><a>No href</a></div>
      <div id="names"><img alt="Foo Inc"><img alt=" "></div>
    </body></html>
  HTML

  def css_model(extra = {})
    {
      'normalize' => 'true',
      'levels' => {
        'first' => { 'name' => 'Gold', 'selector' => 'div#gold a', 'attr' => 'href' },
        'second' => { 'name' => 'Silver', 'selector' => 'div#silver a', 'attr' => 'href' },
        'community' => { 'name' => 'Associate' }
      }
    }.merge(extra)
  end

  def test_as_bool
    assert SponsorUtils.as_bool(true)
    assert SponsorUtils.as_bool('true')
    assert SponsorUtils.as_bool('Yes')
    refute SponsorUtils.as_bool('false')
    refute SponsorUtils.as_bool('')
    refute SponsorUtils.as_bool(nil)
  end

  def test_normalize_href
    assert_equal 'example.com', SponsorUtils.normalize_href(' https://www.Example.COM/Path?Q=1 ')
    assert_equal 'example.com', SponsorUtils.normalize_href('example.com/path')
    assert_equal 'awww.example.com', SponsorUtils.normalize_href('https://awww.example.com/www.x')
    assert_equal 'google.com', SponsorUtils.normalize_href('https://opensource.google/')
    assert_equal 'bloomberg.com', SponsorUtils.normalize_href('https://www.techatbloomberg.com/')
    assert_equal 'notgoogle.com', SponsorUtils.normalize_href('https://notgoogle.com/opensource.google')
    assert_equal 'example.com', SponsorUtils.normalize_href('https://user@example.com:8443/')
    assert_equal 'Foo Inc', SponsorUtils.normalize_href('Foo Inc')
    assert_equal '/relative/path', SponsorUtils.normalize_href('/relative/path')
    assert_equal '', SponsorUtils.normalize_href(nil)
  end

  def test_scrape_bycss_normalizes_dedups_and_skips_unconfigured_levels
    sponsors = nil
    _, err = capture_io { sponsors = SponsorUtils.scrape_bycss(HTML, css_model) }
    assert_equal({ 'first' => ['example.com'], 'second' => ['google.com'], 'community' => [] }, sponsors)
    assert_empty err
  end

  def test_scrape_bycss_respects_string_false_normalize
    sponsors = SponsorUtils.scrape_bycss(HTML, css_model('normalize' => 'false'))
    assert_equal ['https://www.Example.com/About?x=1', 'https://example.com/dup'], sponsors['first']
  end

  def test_scrape_bycss_non_href_attr_and_blank_values
    model = { 'levels' => { 'first' => { 'selector' => 'div#names img', 'attr' => 'alt' } } }
    assert_equal({ 'first' => ['Foo Inc'] }, SponsorUtils.scrape_bycss(HTML, model))
  end

  def test_scrape_bycss_warns_on_empty_level
    model = { 'levels' => { 'first' => { 'selector' => 'div#missing a', 'attr' => 'href' } } }
    _, err = capture_io { SponsorUtils.scrape_bycss(HTML, model) }
    assert_match(/matched no sponsors/, err)
  end

  def test_scrape_bycss_invalid_selector_raises
    model = { 'levels' => { 'first' => { 'selector' => "div#notfound this isn't css", 'attr' => 'href' } } }
    assert_raises(SponsorUtils::ParseError) { SponsorUtils.scrape_bycss(HTML, model) }
  end

  LANDSCAPE_MODEL = {
    'landscape' => 'Members',
    'levels' => {
      'first' => { 'name' => 'Platinum' },
      'second' => { 'name' => 'Gold' }
    }
  }.freeze

  # Standard landscape.yml layout: null keys with sibling name/subcategories/items
  FLAT_LANDSCAPE = <<~YAML
    landscape:
      - category:
        name: Other
        subcategories: []
      - category:
        name: Members
        subcategories:
          - subcategory:
            name: Platinum
            items:
              - item:
                name: Big Co
                homepage_url: https://www.bigco.com/
              - item:
                name: Big Co Again
                homepage_url: https://bigco.com/other
          - subcategory:
            name: Gold
            items:
              - item:
                name: NoUrl
          - subcategory:
            name: Unmapped
            items:
              - item:
                name: Skipped
                homepage_url: https://skipped.example
  YAML

  # Nested layout: name/subcategories/items under the category/subcategory/item key
  NESTED_LANDSCAPE = <<~YAML
    landscape:
      - category:
          name: Members
          subcategories:
            - subcategory:
                name: Platinum
                items:
                  - item:
                      name: Big Co
                      homepage_url: https://www.bigco.com/
            - subcategory:
                name: Gold
                items:
  YAML

  def test_parse_landscape_flat
    sponsors = nil
    _, err = capture_io { sponsors = SponsorUtils.parse_landscape(FLAT_LANDSCAPE, LANDSCAPE_MODEL) }
    assert_equal({ 'first' => ['bigco.com'], 'second' => ['NoUrl'] }, sponsors)
    assert_match(/'Unmapped' matches no configured level/, err)
    refute sponsors.key?('')
  end

  def test_parse_landscape_nested
    sponsors = nil
    _, err = capture_io { sponsors = SponsorUtils.parse_landscape(NESTED_LANDSCAPE, LANDSCAPE_MODEL) }
    assert_equal({ 'first' => ['bigco.com'], 'second' => [] }, sponsors)
    assert_match(/level 'second' \(Gold\) has no sponsors/, err)
  end

  def test_parse_landscape_missing_category_raises
    model = LANDSCAPE_MODEL.merge('landscape' => 'Nope')
    error = assert_raises(SponsorUtils::ParseError) { SponsorUtils.parse_landscape(FLAT_LANDSCAPE, model) }
    assert_match(/category not found/, error.message)
    assert_raises(SponsorUtils::ParseError) { SponsorUtils.parse_landscape("landscape: [\n", LANDSCAPE_MODEL) }
  end

  def test_cleanup_with_map_preserves_parse_date
    in_tmp_project do
      File.write('map.json', JSON.generate('Foo Inc' => 'foo.com'))
      links = { 'first' => ['Foo Inc', 'https://www.bar.com/', 'foo.com'], 'parseDate' => '20240101' }
      assert_equal({ 'first' => ['foo.com', 'bar.com'], 'parseDate' => '20240101' },
                   SponsorUtils.cleanup_with_map(links, 'map.json'))
      assert_raises(SponsorUtils::ParseError) { SponsorUtils.cleanup_with_map(links, 'missing.json') }
    end
  end

  def test_parse_subpages_skips_failures
    model = { 'sponsorroot' => 'https://example.org/', 'sponsorselector' => '.org-link a' }
    subpage = '<div class="org-link"><a href="https://www.member.com/">M</a></div>'
    fetcher = lambda do |url|
      raise SponsorUtils::ParseError, 'fetch: 404' if url.end_with?('/bad')
      url.end_with?('/good') ? subpage : '<p>no link</p>'
    end
    sponsors = nil
    SponsorUtils.stub(:fetch, fetcher) do
      SponsorUtils.stub(:sleep, nil) do
        _, err = capture_io do
          sponsors = SponsorUtils.parse_subpages({ 'first' => ['/good', '/bad', '/nolink', 'https://www.direct.com/x'] }, model)
        end
        assert_match(/404/, err)
        assert_match(/not found/, err)
      end
    end
    assert_equal({ 'first' => ['member.com', 'direct.com'] }, sponsors)
  end

  def test_get_sponsorship_file_reads_front_matter_only
    in_tmp_project do
      write_model('demo', "identifier: demo\nstaticmap: 20240101\n")
      assert_equal 'demo', SponsorUtils.get_sponsorship_file('demo')['identifier']
      assert_raises(SponsorUtils::ParseError) { SponsorUtils.get_sponsorship_file('../etc/passwd') }
      assert_raises(SponsorUtils::ParseError) { SponsorUtils.get_sponsorship_file('missing') }
    end
  end

  def test_process_sponsorship_static_and_empty_scrape
    static = { 'staticmap' => 20240101, 'levels' => { 'first' => { 'sponsors' => ['a.com'] }, 'second' => {} } }
    assert_equal({ 'first' => ['a.com'], 'second' => [], 'parseDate' => 20240101 },
                 SponsorUtils.process_sponsorship('demo', static))
    in_tmp_project do
      File.write('empty.html', '<html><body></body></html>')
      capture_io do
        error = assert_raises(SponsorUtils::ParseError) { SponsorUtils.process_sponsorship('demo', css_model, 'empty.html') }
        assert_match(/no sponsors found/, error.message)
      end
    end
  end

  def test_process_all_sponsorships_continues_after_failures
    in_tmp_project do
      write_model('good', "identifier: good\nstaticmap: 20240101\nlevels:\n  first:\n    sponsors: [a.com]\n")
      write_model('nourl', "identifier: nourl\nlevels: {}\n")
      File.write(File.join(SponsorUtils::SPONSORSHIPS_DIR, 'broken.md'), "---\nfoo: [\n---\n")
      failures = {}
      parsed = SponsorUtils.process_all_sponsorships(failures)
      assert_equal ['good'], parsed.keys
      assert_equal %w[broken nourl], failures.keys.sort
    end
  end

  def test_main_does_not_overwrite_on_failure
    in_tmp_project do
      write_model('demo', "identifier: demo\nsponsorurl: https://example.invalid/\nlevels:\n  first:\n    selector: a\n    attr: href\n")
      File.write('empty.html', '<html></html>')
      outfile = File.join(SponsorUtils::DEFAULT_OUTDIR, 'demo.json')
      File.write(outfile, '{"first":["kept.com"]}')
      code = nil
      _, err = capture_io { code = SponsorUtils.main(%w[--one demo --in empty.html]) }
      assert_equal 1, code
      assert_match(/no sponsors found/, err)
      assert_equal '{"first":["kept.com"]}', File.read(outfile)
    end
  end

  def test_main_one_with_out_file_and_dir
    in_tmp_project do
      write_model('demo', "identifier: demo\nnormalize: true\nsponsorurl: https://example.invalid/\nlevels:\n  first:\n    selector: div#gold a\n    attr: href\n")
      File.write('page.html', HTML)
      assert_equal 0, SponsorUtils.main(%w[-o demo -i page.html --out custom.json])
      assert_equal ['example.com'], JSON.parse(File.read('custom.json'))['first']
      FileUtils.mkdir('outdir')
      assert_equal 0, SponsorUtils.main(%w[-o demo -i page.html --out outdir])
      assert File.exist?('outdir/demo.json')
    end
  end

  def test_main_map_preserves_parse_date
    in_tmp_project do
      File.write(File.join(SponsorUtils::DEFAULT_OUTDIR, 'demo.json'), '{"first":["Foo Inc"],"parseDate":"20240101"}')
      File.write('_data/demo_map.json', '{"Foo Inc":"foo.com"}')
      assert_equal 0, SponsorUtils.main(%w[--map demo])
      assert_equal({ 'first' => ['foo.com'], 'parseDate' => '20240101' },
                   JSON.parse(File.read(File.join(SponsorUtils::DEFAULT_OUTDIR, 'demo.json'))))
    end
  end

  # Minimal one-connection-per-response http server for fetch tests
  def with_http_server(responses)
    server = TCPServer.new('127.0.0.1', 0)
    thread = Thread.new do
      responses.each do |status, headers, body|
        client = server.accept
        while (line = client.gets) && line != "\r\n"; end
        hdrs = { 'Content-Length' => body.bytesize, 'Connection' => 'close' }.merge(headers)
        client.write("HTTP/1.1 #{status}\r\n#{hdrs.map { |k, v| "#{k}: #{v}\r\n" }.join}\r\n#{body}")
        client.close
      end
    end
    yield "http://127.0.0.1:#{server.addr[1]}"
  ensure
    thread&.kill
    server&.close
  end

  def test_fetch_redirects_and_retries
    responses = [['302 Found', { 'Location' => '/next' }, ''], ['503 Service Unavailable', {}, ''], ['200 OK', {}, 'hello']]
    with_http_server(responses) do |base|
      SponsorUtils.stub(:sleep, nil) do
        assert_equal 'hello', SponsorUtils.fetch("#{base}/start")
      end
    end
  end

  def test_fetch_404_raises_without_retry
    with_http_server([['404 Not Found', {}, 'nope']]) do |base|
      error = assert_raises(SponsorUtils::ParseError) { SponsorUtils.fetch("#{base}/x") }
      assert_match(/404/, error.message)
    end
    assert_raises(SponsorUtils::ParseError) { SponsorUtils.fetch('file:///etc/passwd') }
  end
end

class SponsorReportsTest < Minitest::Test
  include TmpProject

  def test_report_funding_discounts_inkind_once_per_sponsor
    in_tmp_project do
      write_model('demo', "identifier: demo\nlevels:\n  first:\n    amount: '1000'\n  firstinkind:\n    amount: '100'\n  odd: {}\n")
      sponsors = { 'demo' => { 'first' => ['a.com'], 'firstinkind' => %w[a.com b.com c.com], 'unknown' => ['d.com'], 'parseDate' => '20240101' } }
      report = SponsorReports.report_funding(sponsors)
      assert_equal({ 'first' => 1000, 'firstinkind' => 300, 'unknown' => 0, 'total' => 1300 }, report['orgs']['demo'])
      assert_equal({ 'a.com' => 1050, 'b.com' => 50, 'c.com' => 50, 'd.com' => 0 }, report['sponsors'])
    end
  end

  def test_report_counts_tolerates_unknown_levels
    counts = SponsorReports.report_counts('demo' => { 'first' => ['a.com'], 'custom' => ['a.com'], 'parseDate' => '1' })
    assert_equal 2, counts['all']['a.com']
    assert_equal 1, counts['custom']['a.com']
  end
end
