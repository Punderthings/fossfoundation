#!/usr/bin/env ruby
module FoundationReporter
  DESCRIPTION = <<-HEREDOC
  FoundationReporter: Various reporting utilities, includes:
    - -f | -c: Simple field and data reporting
    - -r: Use Propublica990, download US IRS 990s, put into foundations_990_common.csv
    - -u: Using UK Charity commission to download UK financial data
  HEREDOC
  module_function
  require 'date'
  require 'yaml'
  require 'json'
  require 'csv'
  require 'pathname'
  require '../propublica990/propublica990'
  require 'optparse'
  require 'faraday'

  DATA_DIRS = {
    'foundations' => File.join(Dir.pwd, '_foundations'),
    'sponsorships' => File.join(Dir.pwd, '_sponsorships'),
    'entities' => File.join(Dir.pwd, '_entities'),
    'p990' => File.join(Dir.pwd, '_data/p990'),
    'taxes' => File.join(Dir.pwd, '_data/taxes')
  }
  DEFAULT_FIELDS = %w[commonName nonprofitStatus orgFocus]
  DISSOLUTION_DATE = 'dissolutionDate'
  META_KEY = 'meta'
  EXCLUDE_KEY = 'exclude'
  IDENTIFIER_KEY = 'identifier'
  DATASET_EXT = '*.md'

  # Get a list of all|current yaml data files of a type
  # @param dataType of yaml from DATA_DIRS
  # @param excludeField name of field to exclude if set (e.g. dissolved foundations) or nil
  # @return hash of meta => {}, dataType  => {identifier => data}, (exclude = {identifier => data})
  def get_dataset(dataType, excludeField = nil)
    raise(ArgumentError, "Invalid data type provided: #{dataType}") if !FoundationReporter::DATA_DIRS.key?(dataType)
    dataset = {META_KEY => {'method' => __method__.to_s, 'dataType' => dataType}, dataType => {}}
    Pathname.glob(File.join(FoundationReporter::DATA_DIRS[dataType], FoundationReporter::DATASET_EXT)) do |file|
      data = YAML.load_file(file)
      dataset[dataType][data[IDENTIFIER_KEY]] = data
    end
    if excludeField
      dataset[META_KEY]['excludeField'] = excludeField
      dataset[EXCLUDE_KEY], dataset[dataType] = dataset[dataType].partition { |k, v| v.has_key?(excludeField) }.map(&:to_h) # FIXME: this detects if key present; we might want if present and nil value
    end
    return dataset
  end

  # Get a list of all available EINs (for US-based Nonprofit501c* only).
  # @param dir pointing to _foundations
  # @return array of strings of EINs
  def get_eins(dir)
    eins = []
    Pathname.glob(File.join(dir, "*.md")) do |file|
      foundation = YAML.load_file(file)
      nonprofit = foundation['nonprofitStatus']
      if nonprofit && nonprofit.include?('Nonprofit501c')
        taxid = foundation['taxID']
        if taxid
          taxid = taxid.to_str.delete('-')
          if taxid.size == 9
            eins << taxid
          else
            puts "WARNING: missing/invalid taxID #{taxid} for #{foundation['identifier']}"
          end
        end
      end
    end
    return eins
  end

  # Gather statistics on a single field in all foundations
  # FIXME: rewrite to match gather_fields() interface
  def gather_field(dir, onefield)
    orgs = {}
    vals = Hash.new{ | h, k | h[k] = [] }
    output = {'orgs' => orgs, 'vals' => vals}
    Dir["#{dir}/*.md"].each do |f|
      begin
        org = YAML.load_file(f)
        data = org.fetch(onefield, nil)
        identifier = File.basename(f, '.md')
        if data
          orgs[identifier] = data
          vals[data] << identifier
        else
          orgs[identifier] = "" # Include foundations with blanks explicitly
        end
      rescue StandardError => e
        puts "ERROR #{e}"
        next # Otherwise ignore errors
      end
    end
    return output
  end

  # Gather statistics on a multiple fields, selecting by first field for non-blank
  # @param dataset to evaluate
  # @param fieldList of fields to report out on; .first selects for non-blank
  def gather_fields(dataset, fieldList)
    orgs = {}
    blankorgs = []
    output = {'orgs' => orgs, 'blanks' => blankorgs}
    dataset.each do |identifier, org|
      begin
        tmp = {}
        fieldList.each do |f|
          tmp[f] = org.fetch(f, "")
        end
        if tmp[fieldList.first].to_s.empty?
          blankorgs << identifier
        else
          orgs[identifier] = tmp
        end
      rescue StandardError => e
        puts "ERROR #{e}"
        next # Silently ignore errors
      end
    end
    return output
  end

  # Report on field usage
  def field_usage(dataset)
    report = {}
    report['orgs'] = []
    report['fieldcount'] = Hash.new(0)
    dataset.each do | org, hash |
      report['orgs'] << org
      hash.each do | k, v |
        report['fieldcount'][k] += 1 if v
      end
    end
    report['fieldcount'] = Hash[report['fieldcount'].sort_by { |k, v| -v }]
    return report
  end

  # Report a set of fields for all active foundations
  # @param dataset to evaluate
  # @param fieldList of fields to report out on; .first selects for non-blank
  # @return hash of orgs and blanks with selected fields
  def foundation_fields(fieldList, csvfile = nil, jsonfile = nil)
    reportFields = fieldList + FoundationReporter::DEFAULT_FIELDS
    fdns = FoundationReporter.get_dataset('foundations', FoundationReporter::DISSOLUTION_DATE)
    report = FoundationReporter.gather_fields(fdns['foundations'], reportFields)
    orgs = report['orgs']
    blanks = report['blanks']
    puts "Active foundations: #{fdns['foundations'].size}, selection field: #{fieldList.first}, orgs with data/blanks: #{orgs.size} / #{blanks.size}"
    puts "Blank orgs: #{report['blanks'].join(', ')}"
    if jsonfile
      File.open(jsonfile, "w") do |f|
        f.write(JSON.pretty_generate(report))
      end
    else
      puts JSON.pretty_generate(report)
    end
    if csvfile
      CSV.open(csvfile, "w", force_quotes: true) do |csv|
        csv << ['identifier', *reportFields]
        orgs.each do |identifier, fields|
          csv << [identifier, *reportFields.map { |field| fields[field] }]
        end
      end
    end
  end

  # Fetch a full report of a single UK charity
  #   NOTE: various hardcoded URLs and identifiers for UK
  # @param registeredNumber of charity from taxID field
  # @param apiToken to access charitycommission.gov.uk
  # @return UK charities data combined hash
  def fetch_ukorg(registeredNumber, apiToken)
    org = {}
    ukCharities = 'https://api.charitycommission.gov.uk'
    faraday = Faraday.new(url: ukCharities) do |config|
      config.response :raise_error
      config.response :json, :content_type => /\bjson$/
      config.adapter :net_http
    end
    faraday.headers['Ocp-Apim-Subscription-Key'] = apiToken
    response = faraday.get("/register/api/allcharitydetailsV2/#{registeredNumber}/0")
    org['organization'] = response.body
    response = faraday.get("/register/api/charityfinancialhistory/#{registeredNumber}/0")
    org['filings'] = response.body
    org['parseDate'] = DateTime.parse(org['organization']['last_modified_time'])
    org['data_source'] = ukCharities
    org['api_version'] = '2'
    return org
  end

  # Load secrets/API keys from a local file
  # @param filename to read secrets from
  # @return relevant apikey TODO: generalize for other cases?
  def get_secrets(filename)
    json = JSON.parse(File.read(filename))
    apikey = json['apikey']
    return apikey
  end

  # ## ### #### ##### ######
  # Check commandline options
  def parse_commandline
    options = {}
    OptionParser.new do |opts|
      opts.on('-h', '--help') { puts "#{DESCRIPTION}\n#{opts}"; exit }
      opts.on('-oOUTFILE', '--out OUTFILE', 'Output filename for operation') do |out|
        options[:out] = out
      end
      opts.on('-fFIELDNAME', '--field FIELDNAME', 'Single field name to report out for all foundations.') do |onefield|
        options[:onefield] = onefield
      end
      opts.on('-cTYPE', '--count TYPE', 'Count field usage of all data files of a type.') do |ctype|
        options[:ctype] = ctype
      end
      opts.on('-rREPORT', '--report REPORT', 'Output default reports.') do |reports|
        options[:reports] = reports
      end
      opts.on('-uUKCHARITY', '--uk UKCHARITY', 'Download a single UK charity report.') do |ukorg|
        options[:ukorg] = ukorg
      end
      opts.on('-lXYZ''--fields x,y,z', Array, 'Report on a custom list of fields (plus DEFAULT_FIELDS).') do |fieldList|
        options[:fieldList] = fieldList
      end
      begin
        opts.parse!
      rescue OptionParser::ParseError => e
        $stderr.puts e
        $stderr.puts opts
        exit 1
      end
    end
    return options
  end
end

# ### #### ##### ######
# Main method for command line use
if __FILE__ == $PROGRAM_NAME
  options = FoundationReporter.parse_commandline
  fieldList = options.fetch(:fieldList, [])
  if fieldList.size > 0
    FoundationReporter.foundation_fields(fieldList, options[:out]) # HACK: print JSON, dump CSV file if provided
    exit 0
  end

  ukorg = options.fetch(:ukorg, nil)
  if ukorg
    outfile = File.join(FoundationReporter::DATA_DIRS['taxes'], "uk-#{ukorg}.json")
    output = FoundationReporter.fetch_ukorg(ukorg, FoundationReporter.get_secrets('../fossfoundation-api.json'))
    File.open(outfile, "w") do |f|
      f.write(JSON.pretty_generate(output))
    end
    puts "Done, wrote out: #{outfile}"
    exit 0
  end

  ctype = options.fetch(:ctype, nil)
  if ctype
    dataset = FoundationReporter.get_dataset(ctype)
    output = FoundationReporter.field_usage(dataset[ctype])
    puts JSON.pretty_generate(output)
  end

  ctype ||= 'foundations'
  onefield = options.fetch(:onefield, nil)
  if onefield
    output = FoundationReporter.gather_field(FoundationReporter::DATA_DIRS[ctype], onefield)
    puts JSON.pretty_generate(output)
  end

  reports = options.fetch(:reports, nil) ### FIXME value of flag unused currently
  options[:out] ||= 'foundations_990_common.csv'
  if reports
    eins = FoundationReporter.get_eins(FoundationReporter::DATA_DIRS['foundations'])
    orgs = Propublica990.get_orgs(eins, FoundationReporter::DATA_DIRS['p990'], refresh = true)
    report_csv = File.join(FoundationReporter::DATA_DIRS['p990'], options[:out])
    Propublica990.orgs2csv_common(orgs, report_csv)
  end
end
