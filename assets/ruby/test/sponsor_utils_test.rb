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
    assert_equal 'example.com', SponsorUtils.normalize_href('https://awww.example.com/www.x')
    assert_equal 'google.com', SponsorUtils.normalize_href('https://opensource.google/')
    assert_equal 'bloomberg.com', SponsorUtils.normalize_href('https://www.techatbloomberg.com/')
    assert_equal 'notgoogle.com', SponsorUtils.normalize_href('https://notgoogle.com/opensource.google')
    assert_equal 'example.com', SponsorUtils.normalize_href('https://user@example.com:8443/')
    assert_equal 'Foo Inc', SponsorUtils.normalize_href('Foo Inc')
    assert_equal '/relative/path', SponsorUtils.normalize_href('/relative/path')
    assert_equal '', SponsorUtils.normalize_href(nil)
  end

  def test_normalize_href_merges_subdomains_and_aliases
    assert_equal 'amazon.com', SponsorUtils.normalize_href('https://aws.amazon.com/opensource')
    assert_equal 'bbc.co.uk', SponsorUtils.normalize_href('https://www.research.bbc.co.uk/')
    assert_equal 'someone.github.io', SponsorUtils.normalize_href('https://someone.github.io/')
    assert_equal 'panasonic.com', SponsorUtils.normalize_href('https://holdings.panasonic/global/')
    assert_equal 'panasonic.com', SponsorUtils.normalize_href('https://automotive.panasonic.com/')
    assert_equal 'meta.com', SponsorUtils.normalize_href('https://about.facebook.com/')
    assert_equal 'uk.osgeo.org', SponsorUtils.normalize_href('https://uk.osgeo.org/'), 'self-alias keeps a subdomain'
    assert_equal '10.1.2.3', SponsorUtils.normalize_href('http://10.1.2.3/')
  end

  def test_renormalize_only_touches_domains
    data = { 'first' => ['aws.amazon.com', 'amazon.com', 'Foo Inc', 'holdings.panasonic'], 'parseDate' => '20240101' }
    assert_equal({ 'first' => ['amazon.com', 'Foo Inc', 'panasonic.com'], 'parseDate' => '20240101' },
                 SponsorUtils.renormalize(data))
  end

  def test_source_type
    assert_equal 'static', SponsorUtils.source_type('staticmap' => 20240101)
    assert_equal 'landscape', SponsorUtils.source_type('landscape' => 'X')
    assert_equal 'css', SponsorUtils.source_type({})
    assert_equal 'landscapejson', SponsorUtils.source_type('sourcetype' => 'LandscapeJSON', 'landscape' => 'X')
    assert_raises(SponsorUtils::ParseError) { SponsorUtils.source_type('sourcetype' => 'pdf') }
  end

  def test_scrape_bycss_refuses_bot_challenge
    html = '<html><head><title>Just a moment...</title></head><body><a href="https://x.com">x</a></body></html>'
    error = assert_raises(SponsorUtils::ParseError) { SponsorUtils.scrape_bycss(html, css_model) }
    assert_match(/bot-detection challenge/, error.message)
  end

  def test_scrape_bycss_normalizes_dedups_and_skips_unconfigured_levels
    sponsors = nil
    _, err = capture_io { sponsors = SponsorUtils.scrape_bycss(HTML, css_model) }
    assert_equal({ 'first' => ['example.com'], 'second' => ['google.com'], 'community' => [] }, sponsors)
    assert_empty err
  end

  def test_scrape_bycss_drops_links_to_own_site
    html = '<html><body><div id="gold"><a href="https://www.example.com/">E</a><a href="https://news.example.com/x">N</a><a href="https://other.org/">O</a></div></body></html>'
    model = css_model('sponsorurl' => 'https://www.example.com/sponsors')
    sponsors = nil
    capture_io { sponsors = SponsorUtils.scrape_bycss(html, model) }
    assert_equal ['other.org'], sponsors['first']
    capture_io { sponsors = SponsorUtils.scrape_bycss(html, css_model('sponsorurl' => 'https://www.example.com/sponsors', 'normalize' => 'false')) }
    assert_equal 3, sponsors['first'].size, 'raw hrefs are kept when not normalizing'
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

  def test_scrape_bycss_xpath_links_after_heading
    html = <<~HTML
      <html><body>
        <h2 id="gold">Gold Sponsors</h2><div><a href="https://gold-a.example/">A</a></div><div><p><a href="https://gold-b.example/">B</a></p></div>
        <h2 id="silver">Silver Sponsors</h2><div><a href="https://silver.example/">S</a><a href="/local">L</a></div>
      </body></html>
    HTML
    model = { 'normalize' => 'true', 'levels' => {
      'first' => { 'selector' => "//a[starts-with(@href, 'http')][preceding::h2[1][@id='gold']]", 'attr' => 'href' },
      'second' => { 'selector' => "(//a[starts-with(@href, 'http')][preceding::h2[1][contains(., 'Silver')]])", 'attr' => 'href' }
    } }
    assert_equal({ 'first' => %w[gold-a.example gold-b.example], 'second' => ['silver.example'] }, SponsorUtils.scrape_bycss(html, model))
    bad = { 'levels' => { 'first' => { 'selector' => '//a[', 'attr' => 'href' } } }
    assert_raises(SponsorUtils::ParseError) { SponsorUtils.scrape_bycss(html, bad) }
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
    assert_match(/'Unmapped' \(1 sponsors\) matches no configured level/, err)
    refute sponsors.key?('')
  end

  def test_parse_landscape_nested
    sponsors = nil
    _, err = capture_io { sponsors = SponsorUtils.parse_landscape(NESTED_LANDSCAPE, LANDSCAPE_MODEL) }
    assert_equal({ 'first' => ['bigco.com'], 'second' => [] }, sponsors)
    assert_match(/level 'second' \(Gold\) has no sponsors/, err)
  end

  def test_parse_landscape_allows_dates
    dated = FLAT_LANDSCAPE.sub("homepage_url: https://www.bigco.com/\n", "homepage_url: https://www.bigco.com/\n            joined: 2019-01-01\n")
    sponsors = nil
    capture_io { sponsors = SponsorUtils.parse_landscape(dated, LANDSCAPE_MODEL) }
    assert_equal ['bigco.com'], sponsors['first']
  end

  def test_parse_landscape_category_names_list
    sponsors = nil
    capture_io { sponsors = SponsorUtils.parse_landscape(FLAT_LANDSCAPE, LANDSCAPE_MODEL.merge('landscape' => ['Renamed Members', 'Members'])) }
    assert_equal ['bigco.com'], sponsors['first']
    error = assert_raises(SponsorUtils::ParseError) { SponsorUtils.parse_landscape(FLAT_LANDSCAPE, LANDSCAPE_MODEL.merge('landscape' => %w[A B])) }
    assert_match(/parse_landscape\(A \| B\): category not found/, error.message)
  end

  def test_parse_landscape_missing_category_raises
    model = LANDSCAPE_MODEL.merge('landscape' => 'Nope')
    error = assert_raises(SponsorUtils::ParseError) { SponsorUtils.parse_landscape(FLAT_LANDSCAPE, model) }
    assert_match(/category not found/, error.message)
    assert_raises(SponsorUtils::ParseError) { SponsorUtils.parse_landscape("landscape: [\n", LANDSCAPE_MODEL) }
  end

  def test_parse_landscape_match_key
    model = { 'landscape' => 'Members', 'levels' => {
      'first' => { 'name' => 'Top', 'match' => %w[Platinum Gold] },
      'second' => { 'name' => 'Other', 'match' => 'unmapped' }
    } }
    sponsors = nil
    capture_io { sponsors = SponsorUtils.parse_landscape(FLAT_LANDSCAPE, model) }
    assert_equal({ 'first' => %w[bigco.com NoUrl], 'second' => ['skipped.example'] }, sponsors)
  end

  # Shape of a landscape2 site's data/full.json
  LANDSCAPE_JSON = JSON.generate(
    'crunchbase_data' => {},
    'items' => [
      { 'category' => 'Members', 'subcategory' => 'Platinum', 'name' => 'Big Co', 'homepage_url' => 'https://www.bigco.com/' },
      { 'category' => 'Members', 'subcategory' => 'Gold', 'name' => 'Gold Co', 'homepage_url' => 'https://dev.goldco.io/' },
      { 'category' => 'Members', 'subcategory' => 'Gold', 'name' => 'No Url Co' },
      { 'category' => 'Members', 'subcategory' => 'End User', 'name' => 'User Co', 'homepage_url' => 'https://user.example/' },
      { 'category' => 'Projects', 'subcategory' => 'Platinum', 'name' => 'Not A Member', 'homepage_url' => 'https://proj.example/' }
    ]
  )

  def test_parse_json_landscapejson
    model = LANDSCAPE_MODEL.merge('sourcetype' => 'landscapejson')
    sponsors = nil
    _, err = capture_io { sponsors = SponsorUtils.parse_json(LANDSCAPE_JSON, model) }
    assert_equal({ 'first' => ['bigco.com'], 'second' => ['goldco.io', 'No Url Co'] }, sponsors)
    assert_match(/'End User' \(1 sponsors\) matches no configured level/, err)
    bad = model.merge('landscape' => 'Nope')
    assert_raises(SponsorUtils::ParseError) { SponsorUtils.parse_json(LANDSCAPE_JSON, bad) }
  end

  def test_parse_json_generic_api
    api = JSON.generate([
      { 'name' => 'IBM', 'website' => 'https://www.ibm.com', 'levels' => [{ 'description' => 'Strategic Member' }] },
      { 'name' => 'Tiny', 'website' => '', 'levels' => [{ 'description' => 'Associate Member' }] },
      { 'name' => 'Old', 'website' => 'https://old.example', 'levels' => [] }
    ])
    model = {
      'sourcetype' => 'json',
      'json' => { 'url' => 'website', 'name' => 'name', 'level' => 'levels.description' },
      'levels' => { 'first' => { 'name' => 'Strategic', 'match' => 'Strategic Member' },
                    'third' => { 'name' => 'Associate', 'match' => 'associate member' } }
    }
    sponsors = nil
    _, err = capture_io { sponsors = SponsorUtils.parse_json(api, model) }
    assert_equal({ 'first' => ['ibm.com'], 'third' => ['Tiny'] }, sponsors)
    assert_match(/'\(no level\)'/, err)
    nested = JSON.generate('data' => { 'members' => JSON.parse(api) })
    capture_io do
      assert_equal ['ibm.com'], SponsorUtils.parse_json(nested, model.merge('json' => model['json'].merge('items' => 'data.members')))['first']
    end
    assert_raises(SponsorUtils::ParseError) { SponsorUtils.parse_json('{"a":1}', model) }
    assert_raises(SponsorUtils::ParseError) { SponsorUtils.parse_json('not json', model) }
  end

  def test_parse_yaml_items_by_key_and_default_level
    yaml = <<~YAML
      hosting:
        - name: Host Co
          link: https://www.host.example/
      specific:
        - name: Gift Co
      former:
        - name: Old Co
          link: https://old.example/
    YAML
    model = { 'sourcetype' => 'yaml', 'json' => { 'itemsByKey' => true, 'url' => 'link', 'name' => 'name', 'level' => '_key' },
              'levels' => { 'firstinkind' => { 'match' => 'hosting' }, 'secondinkind' => { 'match' => 'specific' } } }
    sponsors = nil
    _, err = capture_io { sponsors = SponsorUtils.parse_json(yaml, model) }
    assert_equal({ 'firstinkind' => ['host.example'], 'secondinkind' => ['Gift Co'] }, sponsors)
    assert_match(/'former' \(1 sponsors\)/, err)

    members = "- {name: A, url: https://a.example, member: true, membertype: 2}\n- {name: B, url: https://b.example, member: true}\n" \
              "- {name: C, url: https://c.example, member: false}\n"
    tiers = { 'sourcetype' => 'yaml', 'json' => { 'url' => 'url', 'level' => 'membertype', 'defaultLevel' => 'third', 'filter' => { 'member' => 'true' } },
              'levels' => { 'first' => { 'match' => '2' }, 'third' => { 'match' => '4' } } }
    assert_equal({ 'first' => ['a.example'], 'third' => ['b.example'] }, SponsorUtils.parse_json(members, tiers))
    assert_raises(SponsorUtils::ParseError) { SponsorUtils.parse_json("a: [\n", tiers) }
  end

  def test_dig_all
    obj = { 'a' => [{ 'b' => 'x' }, { 'b' => ['y', nil] }, { 'c' => 'z' }] }
    assert_equal %w[x y], SponsorUtils.dig_all(obj, 'a.b')
    assert_equal [obj], SponsorUtils.dig_all(obj, '')
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

  def test_main_refuses_suspicious_drop_unless_forced
    in_tmp_project do
      write_model('demo', "identifier: demo\nnormalize: true\nsponsorurl: https://example.invalid/\nlevels:\n  first:\n    selector: div#gold a\n    attr: href\n")
      File.write('page.html', SponsorUtilsTest::HTML)
      outfile = File.join(SponsorUtils::DEFAULT_OUTDIR, 'demo.json')
      previous = JSON.generate('first' => (1..12).map { |i| "s#{i}.com" }, 'parseDate' => '20240101')
      File.write(outfile, previous)
      _, err = capture_io { assert_equal 1, SponsorUtils.main(%w[-o demo -i page.html]) }
      assert_match(/suspicious drop.*total dropped from 12 to 1/, err)
      assert_equal previous, File.read(outfile)
      capture_io { assert_equal 0, SponsorUtils.main(%w[-o demo -i page.html --force]) }
      assert_equal ['example.com'], JSON.parse(File.read(outfile))['first']
    end
  end

  def test_drift_problems
    old = { 'first' => %w[a b c d e], 'second' => %w[f], 'parseDate' => '1' }
    assert_equal ["level 'first' dropped from 5 to 0"], SponsorUtils.drift_problems(old, 'first' => [], 'second' => %w[f g h i j k])
    assert_empty SponsorUtils.drift_problems(old, 'first' => %w[a b], 'second' => %w[f])
    assert_empty SponsorUtils.drift_problems(nil, 'first' => [])
  end

  def test_age_days
    today = Date.new(2026, 1, 11)
    assert_equal 10, SponsorUtils.age_days('20260101', today)
    assert_equal 10, SponsorUtils.age_days(20260101, today)
    assert_nil SponsorUtils.age_days(nil, today)
    assert_nil SponsorUtils.age_days('soon', today)
  end

  def test_check_sponsorships_statuses
    in_tmp_project do
      out = SponsorUtils::DEFAULT_OUTDIR
      write_model('fresh', "identifier: fresh\nstaticmap: 20260101\nlevels:\n  first:\n    sponsors: [a.com]\n")
      File.write("#{out}/fresh.json", '{"first":["a.com"],"parseDate":20260101}')
      write_model('old', "identifier: old\nstaticmap: 20200101\nlevels:\n  first:\n    sponsors: [a.com]\n")
      File.write("#{out}/old.json", '{"first":["a.com"],"parseDate":20200101}')
      write_model('live', "identifier: live\nsponsorurl: https://example.invalid/\nnormalize: true\nlevels:\n  first:\n    selector: div#gold a\n    attr: href\n")
      File.write("#{out}/live.json", '{"first":["example.com","gone.com"],"parseDate":"20260101"}')
      write_model('broken', "identifier: broken\nsponsorurl: https://example.invalid/\nlevels: {}\n")
      today = Date.new(2026, 2, 1)
      results = nil
      SponsorUtils.stub(:fetch, ->(_url) { SponsorUtilsTest::HTML }) do
        capture_io { results = SponsorUtils.check_sponsorships(%w[fresh old live broken], max_age: 365, today: today) }
      end
      statuses = results.to_h { |r| [r[:org], r[:statuses]] }
      assert_equal({ 'fresh' => ['ok'], 'old' => ['stale'], 'live' => ['changed'], 'broken' => %w[missing failed] }, statuses)
      live = results.find { |r| r[:org] == 'live' }
      assert_equal ['gone.com'], live[:diff]['first'][:removed]
      out_text, = capture_io { assert_equal 1, SponsorUtils.report_check(results, 365) }
      assert_match(/live\s+changed.*first:2->1\(\+0\/-1\)/, out_text)
      offline = nil
      capture_io { offline = SponsorUtils.check_sponsorships(%w[fresh live], offline: true, today: today) }
      assert_equal [['ok'], ['ok']], offline.map { |r| r[:statuses] }
      capture_io { assert_equal 0, SponsorUtils.report_check(offline, 365) }
    end
  end

  def test_main_renormalize
    in_tmp_project do
      path = File.join(SponsorUtils::DEFAULT_OUTDIR, 'demo.json')
      File.write(path, '{"first":["cloud.google.com","google.com"],"parseDate":"20240101"}')
      capture_io { assert_equal 0, SponsorUtils.main(%w[--renormalize]) }
      assert_equal({ 'first' => ['google.com'], 'parseDate' => '20240101' }, JSON.parse(File.read(path)))
    end
  end

  # A stand-in for Chrome that prints the html in $FAKE_DOM, ignoring its arguments
  def with_fake_chrome(script_body)
    Dir.mktmpdir do |dir|
      bin = File.join(dir, 'fake-chrome')
      File.write(bin, "#!/bin/sh\n#{script_body}\n")
      File.chmod(0o755, bin)
      original = ENV.fetch('CHROME_BIN', nil)
      ENV['CHROME_BIN'] = bin
      yield
    ensure
      ENV['CHROME_BIN'] = original
    end
  end

  def test_render_page_with_chrome
    fake = %q{case "$*" in *--dump-dom*) echo '<html><body><div id="gold"><a href="https://rendered.example/">R</a></div></body></html>';; esac}
    with_fake_chrome(fake) do
      model = { 'sponsorurl' => 'https://example.org/members', 'render' => 'chrome', 'normalize' => 'true',
                'levels' => { 'first' => { 'selector' => 'div#gold a', 'attr' => 'href' } } }
      assert_equal ['rendered.example'], SponsorUtils.parse_sponsorship('demo', model)['first']
    end
    with_fake_chrome('exit 3') do
      error = assert_raises(SponsorUtils::ParseError) { SponsorUtils.render_page('https://example.org/') }
      assert_match(/no output/, error.message)
    end
    # Like Chrome on macOS: prints the DOM, then keeps running
    with_fake_chrome("echo '<html><body>done</body></html>'; sleep 30") do
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      assert_match(/done/, SponsorUtils.render_page('https://example.org/'))
      assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 10
    end
    assert_raises(SponsorUtils::ParseError) { SponsorUtils.read_source('sponsorurl' => 'https://example.org/', 'render' => 'firefox') }
    assert_raises(SponsorUtils::ParseError) { SponsorUtils.render_page('file:///etc/passwd') }
  end

  def test_date_key
    assert_equal '20240115', SponsorUtils.date_key('20240115')
    assert_equal '20240115', SponsorUtils.date_key(20240115)
    assert_equal '20240115', SponsorUtils.date_key('2024-01-15')
    assert_equal '20240115', SponsorUtils.date_key(Date.new(2024, 1, 15))
    assert_nil SponsorUtils.date_key(nil)
    assert_nil SponsorUtils.date_key(' ')
    %w[2024 20241315 soon 2024-1-5].each do |bad|
      assert_raises(SponsorUtils::ParseError, bad) { SponsorUtils.date_key(bad) }
    end
  end

  DATED_MODEL = {
    'identifier' => 'demo',
    'levelurl' => 'https://example.org/2026',
    'effectiveDate' => '20260101',
    'levels' => {
      'first' => { 'name' => 'Gold', 'amount' => '18000', 'benefits' => { 'logo' => 'yes' } },
      'second' => { 'name' => 'Silver', 'amount' => '3600' },
      'third' => { 'name' => 'Bronze', 'amount' => '720' }
    },
    'pastModels' => [
      { 'effectiveDate' => 20200101, 'levelurl' => 'https://example.org/2020',
        'levels' => { 'first' => { 'amount' => '10000' }, 'third' => nil } },
      { 'effectiveDate' => Date.new(2023, 7, 1),
        'levels' => { 'first' => { 'name' => 'Golden', 'amount' => '12000' }, 'fourth' => { 'name' => 'Tin', 'amount' => '50' } } }
    ]
  }.freeze

  def test_model_at_current_and_past
    current = SponsorUtils.model_at(DATED_MODEL)
    refute current.key?('pastModels')
    assert_equal '18000', current['levels']['first']['amount']
    assert_equal current, SponsorUtils.model_at(DATED_MODEL, '20260101')
    assert_equal current, SponsorUtils.model_at(DATED_MODEL, '20991231')

    mid = SponsorUtils.model_at(DATED_MODEL, '2024-09-26')
    assert_equal '20230701', mid['effectiveDate']
    assert_equal({ 'name' => 'Golden', 'amount' => '12000', 'benefits' => { 'logo' => 'yes' } }, mid['levels']['first'])
    assert_equal({ 'name' => 'Tin', 'amount' => '50' }, mid['levels']['fourth'])
    assert_equal '720', mid['levels']['third']['amount'], 'entries differ from the current model, not from each other'
    assert_equal 'https://example.org/2026', mid['levelurl']

    old = SponsorUtils.model_at(DATED_MODEL, 20210615)
    assert_equal '20200101', old['effectiveDate']
    assert_equal({ 'name' => 'Gold', 'amount' => '10000', 'benefits' => { 'logo' => 'yes' } }, old['levels']['first'])
    refute old['levels'].key?('third'), 'null removes a level that did not exist then'
    assert_equal 'https://example.org/2020', old['levelurl']
    assert_equal old, SponsorUtils.model_at(DATED_MODEL, '19990101'), 'before the earliest model uses the earliest'

    assert_equal '18000', DATED_MODEL['levels']['first']['amount'], 'input model is not modified'
  end

  def test_model_at_without_past_models
    model = { 'levels' => { 'first' => { 'amount' => '1' } }, 'pastModels' => [] }
    assert_equal({ 'levels' => { 'first' => { 'amount' => '1' } } }, SponsorUtils.model_at(model, '20000101'))
    assert_equal({ 'levels' => {} }, SponsorUtils.model_at({ 'levels' => {} }, '20000101'))
  end

  def test_model_at_validation
    base = { 'effectiveDate' => '20250101', 'levels' => {} }
    {
      'missing current date' => base.merge('effectiveDate' => nil, 'pastModels' => [{ 'effectiveDate' => '20200101' }]),
      'entry without date' => base.merge('pastModels' => [{ 'levels' => {} }]),
      'duplicate dates' => base.merge('pastModels' => [{ 'effectiveDate' => '20200101' }, { 'effectiveDate' => '2020-01-01' }]),
      'past not earlier' => base.merge('pastModels' => [{ 'effectiveDate' => '20250101' }]),
      'not a list' => base.merge('pastModels' => { 'effectiveDate' => '20200101' }),
      'bad level' => base.merge('pastModels' => [{ 'effectiveDate' => '20200101', 'levels' => { 'first' => '100' } }]),
      'bad date' => base.merge('pastModels' => [{ 'effectiveDate' => 'last year' }])
    }.each do |label, model|
      assert_raises(SponsorUtils::ParseError, label) { SponsorUtils.model_at(model, '20210101') }
    end
  end

  def test_get_sponsorship_file_accepts_dated_models
    in_tmp_project do
      write_model('demo', "identifier: demo\neffectiveDate: '20250101'\nlevels:\n  first:\n    amount: '18000'\n" \
                          "pastModels:\n  - effectiveDate: 2019-01-01\n    levels:\n      first:\n        amount: '12000'\n")
      model = SponsorUtils.get_sponsorship_file('demo')
      assert_equal '12000', SponsorUtils.model_at(model, '20240926')['levels']['first']['amount']
      assert_equal '18000', SponsorUtils.model_at(model)['levels']['first']['amount']
    end
  end

  def test_level_lists
    assert_equal({ 'first' => %w[a.com b.com] }, SponsorUtils.level_lists('first' => ['b.com', 'a.com', 'b.com', ' '], 'second' => [], 'parseDate' => '1'))
  end

  def record(sponsors, date, **opts)
    SponsorUtils.record_sponsors('demo', File.join(SponsorUtils::DEFAULT_OUTDIR, 'demo.json'), sponsors,
                                 history_dir: SponsorUtils::DEFAULT_HISTORY_DIR, today: Date.strptime(date, '%Y%m%d'), **opts)
  end

  def current_data = JSON.parse(File.read(File.join(SponsorUtils::DEFAULT_OUTDIR, 'demo.json')))
  def history_data = SponsorUtils.load_history(File.join(SponsorUtils::DEFAULT_HISTORY_DIR, 'demo.json'))
  def spans_of(hist) = hist['spans'].map { |sp| sp.values_at('sponsor', 'level', 'firstSeen', 'lastSeen') }

  def test_record_sponsors_lifecycle
    in_tmp_project do
      assert_equal :new, record({ 'first' => %w[b.com a.com], 'parseDate' => '20260101' }, '20260101')
      assert_equal({ 'first' => %w[b.com a.com], 'parseDate' => '20260101', 'lastChecked' => '20260101' }, current_data)
      assert_equal [%w[a.com first 20260101] + [nil], %w[b.com first 20260101] + [nil]], spans_of(history_data)

      assert_equal :unchanged, record({ 'first' => %w[a.com b.com], 'parseDate' => '20260115' }, '20260115')
      assert_equal '20260101', current_data['parseDate'], 'unchanged lists keep their first-observed date'
      assert_equal '20260115', current_data['lastChecked']
      assert_equal 1, history_data['scrapes'].size, 'unchanged runs do not touch history'

      assert_equal :changed, record({ 'first' => %w[a.com c.com], 'second' => %w[b.com], 'parseDate' => '20260201' }, '20260201')
      hist = history_data
      assert_equal [{ 'parseDate' => '20260101', 'lastChecked' => '20260115', 'source' => 'scrape', 'counts' => { 'first' => 2 } },
                    { 'parseDate' => '20260201', 'lastChecked' => '20260201', 'source' => 'scrape', 'counts' => { 'first' => 2, 'second' => 1 } }],
                   hist['scrapes']
      assert_equal [['a.com', 'first', '20260101', nil], %w[b.com first 20260101 20260115],
                    ['c.com', 'first', '20260201', nil], ['b.com', 'second', '20260201', nil]], spans_of(hist)

      record({ 'first' => %w[a.com c.com d.com], 'second' => %w[b.com], 'parseDate' => '20260201' }, '20260201')
      assert_equal %w[20260101 20260201], history_data['scrapes'].map { |sc| sc['parseDate'] }, 'same-day change replaces that scrape'
      assert_includes spans_of(history_data), ['d.com', 'first', '20260201', nil]

      assert_raises(SponsorUtils::ParseError) { record({ 'first' => %w[z.com], 'parseDate' => '20250101' }, '20250101') }
      states = SponsorUtils.history_states(history_data).map(&:last)
      assert_equal [{ 'first' => %w[a.com b.com] }, { 'first' => %w[a.com c.com d.com], 'second' => %w[b.com] }], states
    end
  end

  def test_record_sponsors_seeds_history_from_existing_data
    in_tmp_project do
      File.write(File.join(SponsorUtils::DEFAULT_OUTDIR, 'demo.json'),
                 '{"first":["a.com"],"parseDate":"20250101","lastChecked":"20260131"}')
      record({ 'first' => %w[b.com], 'parseDate' => '20260201' }, '20260201')
      assert_equal [{ 'parseDate' => '20250101', 'lastChecked' => '20260131', 'source' => 'previous', 'counts' => { 'first' => 1 } },
                    { 'parseDate' => '20260201', 'lastChecked' => '20260201', 'source' => 'scrape', 'counts' => { 'first' => 1 } }],
                   history_data['scrapes']
      assert_equal [%w[a.com first 20250101 20260131], ['b.com', 'first', '20260201', nil]], spans_of(history_data)
    end
  end

  def test_record_sponsors_change_on_last_checked_day
    in_tmp_project do
      record({ 'first' => %w[a.com], 'parseDate' => '20260101' }, '20260101')
      record({ 'first' => %w[a.com], 'parseDate' => '20260201' }, '20260201')
      record({ 'first' => %w[b.com], 'parseDate' => '20260201' }, '20260201')
      assert_equal %w[a.com first 20260101 20260131], spans_of(history_data).first, 'earlier list confirmed until the day before'
      assert_equal [{ 'first' => %w[a.com] }, { 'first' => %w[b.com] }], SponsorUtils.history_states(history_data).map(&:last)
    end
  end

  def test_record_sponsors_static_forced_and_no_history
    in_tmp_project do
      model = { 'staticmap' => 20240112, 'effectiveDate' => '20230101' }
      record({ 'first' => %w[a.com], 'parseDate' => 20240112 }, '20261007', model: model)
      assert_equal({ 'first' => %w[a.com], 'parseDate' => '20240112', 'lastChecked' => '20240112' }, current_data)
      assert_equal [{ 'parseDate' => '20240112', 'lastChecked' => '20240112', 'source' => 'manual', 'modelDate' => '20230101', 'counts' => { 'first' => 1 } }],
                   history_data['scrapes']

      big = { 'first' => (1..12).map { |i| "s#{i}.com" }, 'parseDate' => '20260101' }
      record(big, '20260101')
      capture_io { record({ 'first' => %w[s1.com], 'parseDate' => '20260201' }, '20260201', force: true) }
      assert history_data['scrapes'].last['forced']

      path = File.join(SponsorUtils::DEFAULT_OUTDIR, 'other.json')
      SponsorUtils.record_sponsors('other', path, { 'first' => %w[x.com], 'parseDate' => '20260101' })
      refute File.exist?(File.join(SponsorUtils::DEFAULT_HISTORY_DIR, 'other.json'))
    end
  end

  def monthly_entries(*states)
    dates = %w[20260131 20260228 20260331 20260430 20260531 20260630]
    states.each_with_index.map { |state, i| [{ 'parseDate' => dates[i], 'lastChecked' => dates[i] }, state] }
  end

  def test_build_history_bridges_one_missed_month
    entries = monthly_entries({ 'first' => %w[a.com b.com] }, { 'first' => %w[a.com] }, { 'first' => %w[a.com b.com] })
    hist = SponsorUtils.build_history('demo', entries)
    assert_equal [{ 'sponsor' => 'a.com', 'level' => 'first', 'firstSeen' => '20260131', 'lastSeen' => nil },
                  { 'sponsor' => 'b.com', 'level' => 'first', 'firstSeen' => '20260131', 'lastSeen' => nil, 'missing' => ['20260228'] }], hist['spans']
    assert_equal [2, 1, 2], hist['scrapes'].map { |sc| sc['counts']['first'] }, 'counts stay as observed'
    assert_equal entries.map(&:last), SponsorUtils.history_states(hist).map(&:last), 'every list can be rebuilt exactly'
  end

  def test_build_history_does_not_bridge_longer_absences
    two_months = monthly_entries({ 'first' => %w[a.com b.com] }, { 'first' => %w[a.com] }, { 'first' => %w[a.com] }, { 'first' => %w[a.com b.com] })
    hist = SponsorUtils.build_history('demo', two_months)
    assert_equal [%w[b.com 20260131 20260131], ['b.com', '20260430', nil]],
                 hist['spans'].select { |sp| sp['sponsor'] == 'b.com' }.map { |sp| sp.values_at('sponsor', 'firstSeen', 'lastSeen') }
    assert_equal two_months.map(&:last), SponsorUtils.history_states(hist).map(&:last)

    yearly = [[{ 'parseDate' => '20230101', 'lastChecked' => '20231231' }, { 'first' => %w[b.com] }],
              [{ 'parseDate' => '20240101', 'lastChecked' => '20241231' }, { 'first' => %w[c.com] }],
              [{ 'parseDate' => '20250101', 'lastChecked' => '20251231' }, { 'first' => %w[b.com] }]]
    assert_equal 2, SponsorUtils.build_history('demo', yearly)['spans'].count { |sp| sp['sponsor'] == 'b.com' }, 'a missing year is not bridged'

    ended = SponsorUtils.build_history('demo', monthly_entries({ 'first' => %w[a.com b.com] }, { 'first' => %w[a.com] }))
    assert_equal '20260131', ended['spans'].find { |sp| sp['sponsor'] == 'b.com' }['lastSeen'], 'an absence at the end is a departure'
  end

  def test_build_history_bridge_disabled_and_level_moves
    entries = monthly_entries({ 'first' => %w[a.com] }, { 'second' => %w[a.com] }, { 'first' => %w[a.com] })
    unbridged = SponsorUtils.build_history('demo', entries, bridge: 0)
    assert_equal [%w[first 20260131 20260131], ['first', '20260331', nil], %w[second 20260228 20260228]],
                 unbridged['spans'].map { |sp| sp.values_at('level', 'firstSeen', 'lastSeen') }
    refute(unbridged['spans'].any? { |sp| sp.key?('missing') })
    bridged = SponsorUtils.build_history('demo', entries)
    assert_equal 2, bridged['spans'].size
    assert_equal entries.map(&:last), SponsorUtils.history_states(bridged).map(&:last)
  end

  def test_bridge_days_setting
    assert_equal 31, SponsorUtils.bridge_days
    SponsorUtils.bridge_days = 0
    assert_equal 0, SponsorUtils.bridge_days
    assert_raises(ArgumentError) { SponsorUtils.bridge_days = -1 }
    in_tmp_project do
      SponsorUtils.bridge_days = nil
      hist = SponsorUtils.build_history('demo', monthly_entries({ 'first' => %w[a.com b.com] }, { 'first' => %w[a.com] }, { 'first' => %w[a.com b.com] }))
      SponsorUtils.write_history(File.join(SponsorUtils::DEFAULT_HISTORY_DIR, 'demo.json'), hist)
      capture_io { assert_equal 0, SponsorUtils.main(%w[--renormalize --bridge-days 0]) }
      assert_equal 0, SponsorUtils.bridge_days
      spans = history_data['spans'].select { |sp| sp['sponsor'] == 'b.com' }
      assert_equal 2, spans.size, 'renormalizing with --bridge-days 0 splits the bridged span'
    end
  ensure
    SponsorUtils.bridge_days = nil
  end

  def test_history_json_is_one_row_per_line
    hist = SponsorUtils.build_history('demo', [[{ 'parseDate' => '20260101', 'lastChecked' => '20260101' }, { 'first' => %w[a.com b.com] }]])
    text = SponsorUtils.history_json(hist)
    assert_equal hist, JSON.parse(text)
    assert_equal 2, text.lines.grep(/"sponsor":/).size
    assert_equal({ 'org' => 'x', 'scrapes' => [], 'spans' => [] }, JSON.parse(SponsorUtils.history_json(SponsorUtils.build_history('x', []))))
  end

  def test_renormalize_history_files_merges_spans
    in_tmp_project do
      hist = SponsorUtils.build_history('demo', [
        [{ 'parseDate' => '20240101', 'lastChecked' => '20240101' }, { 'first' => %w[cloud.google.com] }],
        [{ 'parseDate' => '20250101', 'lastChecked' => '20250101' }, { 'first' => %w[google.com] }]
      ])
      SponsorUtils.write_history(File.join(SponsorUtils::DEFAULT_HISTORY_DIR, 'demo.json'), hist)
      capture_io { assert_equal 0, SponsorUtils.main(%w[--renormalize]) }
      assert_equal [['google.com', 'first', '20240101', nil]], spans_of(history_data)
      assert_equal 2, history_data['scrapes'].size
    end
  end

  def git!(*args)
    out, status = Open3.capture2e('git', '-c', 'user.name=Test', '-c', 'user.email=test@example.org', '-c', 'commit.gpgsign=false', *args)
    assert status.success?, out
  end

  def commit_file(path, content, message)
    File.write(path, content)
    git!('add', path)
    git!('commit', '-q', '--no-verify', '-m', message)
  end

  def test_backfill_history_from_git
    in_tmp_project do
      git!('init', '-q')
      out = SponsorUtils::DEFAULT_OUTDIR
      commit_file('_data/allsponsorships.json',
                  JSON.generate('demo' => { 'first' => ['a.com', 'ERROR: scrape failed'], 'parseDate' => '20240208' }, 'other' => {}), 'all')
      commit_file("#{out}/demo.json", JSON.generate('first' => ['www.a.com'], 'parseDate' => '20240215'), 'v1')
      commit_file("#{out}/demo.json", JSON.generate('error' => 'ERROR: 404', 'parseDate' => '20240501'), 'error blob')
      commit_file("#{out}/demo.json", JSON.generate('first' => [], 'parseDate' => '20240926'), 'empty scrape')
      commit_file("#{out}/demo.json", JSON.generate('first' => %w[a.com b.com], 'parseDate' => '20250911'), 'v2')
      File.write("#{out}/demo.json", JSON.generate('first' => %w[b.com a.com], 'parseDate' => '20250911', 'lastChecked' => '20261001'))
      write_model('demo', "identifier: demo\neffectiveDate: '20250101'\nlevels:\n  first:\n    amount: '1'\n" \
                          "pastModels:\n  - effectiveDate: '20200101'\n    levels:\n      first:\n        amount: '2'\n")

      out_text, = capture_io { assert_equal 0, SponsorUtils.main(%w[--backfill-git --one demo]) }
      assert_match(/Backfilled 1/, out_text)
      hist = history_data
      assert_equal [{ 'parseDate' => '20240208', 'lastChecked' => '20240215', 'source' => 'git', 'modelDate' => '20200101', 'counts' => { 'first' => 1 } },
                    { 'parseDate' => '20250911', 'lastChecked' => '20250911', 'source' => 'git', 'modelDate' => '20250101', 'counts' => { 'first' => 2 } }],
                   hist['scrapes']
      assert_equal [['a.com', 'first', '20240208', nil], ['b.com', 'first', '20250911', nil]], spans_of(hist)

      _, err = capture_io { SponsorUtils.main(%w[--backfill-git --one demo]) }
      assert_match(/exists; skipping/, err)
    end
  end

  def test_version_state_skips_unusable_versions
    assert_equal ['20240101', { 'first' => %w[a.com b.com], 'second' => %w[c.com] }],
                 SponsorUtils.version_state('first' => %w[www.b.com a.com], 'second' => ['c.com', 'ERROR: x'], 'parseDate' => 20240101)
    assert_nil SponsorUtils.version_state('first' => %w[a.com b.com], 'fourth' => %w[b.com a.com], 'parseDate' => '20240101'), 'duplicated level'
    refute_nil SponsorUtils.version_state('first' => %w[a.com], 'fourth' => %w[a.com], 'parseDate' => '20240101'), 'one shared sponsor is plausible'
    assert_nil SponsorUtils.version_state('first' => [], 'parseDate' => '20240101')
    assert_nil SponsorUtils.version_state('error' => 'ERROR: 404', 'parseDate' => '20240101')
    assert_nil SponsorUtils.version_state('first' => %w[a.com], 'parseDate' => 'soon')
    assert_nil SponsorUtils.version_state('first' => %w[a.com])
    assert_nil SponsorUtils.version_state(nil)
  end

  def test_history_dir_for
    assert_equal 'history/sponsorships', SponsorUtils.history_dir_for({})
    assert_nil SponsorUtils.history_dir_for(out: 'tmp')
    assert_nil SponsorUtils.history_dir_for(orgid: 'x', infile: 'page.html')
    assert_equal 'h', SponsorUtils.history_dir_for(out: 'tmp', history: 'h')
    assert_nil SponsorUtils.history_dir_for(history: 'h', no_history: true)
  end

  def test_check_age_uses_last_checked
    in_tmp_project do
      write_model('demo', "identifier: demo\nstaticmap: 20200101\nlevels:\n  first:\n    sponsors: [a.com]\n")
      File.write(File.join(SponsorUtils::DEFAULT_OUTDIR, 'demo.json'), '{"first":["a.com"],"parseDate":"20200101","lastChecked":"20260101"}')
      results = SponsorUtils.check_sponsorships(%w[demo], today: Date.new(2026, 2, 1))
      assert_equal 31, results.first[:age]
      assert_equal ['ok'], results.first[:statuses]
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

  def test_report_funding_uses_amounts_in_effect_at_parse_date
    in_tmp_project do
      write_model('demo', "identifier: demo\neffectiveDate: '20250101'\nlevels:\n  first:\n    amount: '18000'\n" \
                          "pastModels:\n  - effectiveDate: '20190101'\n    levels:\n      first:\n        amount: '12000'\n")
      old_list = { 'demo' => { 'first' => %w[a.com b.com], 'parseDate' => '20240926' } }
      new_list = { 'demo' => { 'first' => %w[a.com b.com], 'parseDate' => 20250315 } }
      assert_equal 24_000, SponsorReports.report_funding(old_list)['orgs']['demo']['total']
      assert_equal 36_000, SponsorReports.report_funding(new_list)['orgs']['demo']['total']
      assert_equal 36_000, SponsorReports.report_funding(old_list, as_of: '20260101')['orgs']['demo']['total']
      assert_equal({ 'a.com' => 12_000, 'b.com' => 12_000 }, SponsorReports.report_funding(new_list, as_of: '20200101')['sponsors'])
      undated = { 'demo' => { 'first' => %w[a.com] } }
      assert_equal 18_000, SponsorReports.report_funding(undated)['orgs']['demo']['total']
    end
  end

  def test_report_history_summary
    in_tmp_project do
      write_model('demo', "identifier: demo\neffectiveDate: '20250101'\nlevels:\n  first:\n    amount: '100'\n  second:\n    amount: '10'\n" \
                          "pastModels:\n  - effectiveDate: '20200101'\n    levels:\n      first:\n        amount: '50'\n")
      hist = SponsorUtils.build_history('demo', [
        [{ 'parseDate' => '20240101', 'lastChecked' => '20240301' }, { 'first' => %w[a.com b.com] }],
        [{ 'parseDate' => '20250601', 'lastChecked' => '20250601' }, { 'first' => %w[a.com], 'second' => %w[c.com d.com] }]
      ])
      SponsorUtils.write_history(File.join(SponsorUtils::DEFAULT_HISTORY_DIR, 'demo.json'), hist)
      no_model = SponsorUtils.build_history('nomodel', [[{ 'parseDate' => '20240101', 'lastChecked' => '20240101' }, { 'first' => %w[x.com] }]])
      SponsorUtils.write_history(File.join(SponsorUtils::DEFAULT_HISTORY_DIR, 'nomodel.json'), no_model)
      report = SponsorReports.report_history(SponsorUtils::DEFAULT_HISTORY_DIR, 'demo' => { 'lastChecked' => '20261001' })
      assert_equal [{ 'parseDate' => '20240101', 'lastChecked' => '20240301', 'sponsors' => 2, 'levels' => { 'first' => 2 }, 'estimate' => 100 },
                    { 'parseDate' => '20250601', 'lastChecked' => '20261001', 'sponsors' => 3, 'levels' => { 'first' => 1, 'second' => 2 }, 'estimate' => 120 }],
                   report['demo']
      assert_nil report['nomodel'].first['estimate']
    end
  end

  def test_report_counts_tolerates_unknown_levels
    counts = SponsorReports.report_counts('demo' => { 'first' => ['a.com'], 'custom' => ['a.com'], 'parseDate' => '1' })
    assert_equal 2, counts['all']['a.com']
    assert_equal 1, counts['custom']['a.com']
  end
end
