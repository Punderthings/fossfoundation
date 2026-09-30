#!/usr/bin/env ruby
module FoundationReporter
  DESCRIPTION = <<-HEREDOC
  FoundationReporter: Various reporting utilities, includes:
    - -f | -c: Simple field and data reporting
    - -r: Use Propublica990, download US IRS 990s, put into foundations_990_common.csv
    - -u: Using UK Charity commission to download UK financial data
  HEREDOC
  
  # Constants for configuration
  MAX_RETRY_ATTEMPTS = 3
  REQUEST_TIMEOUT = 30 # seconds
  MAX_FILE_SIZE = 10 * 1024 * 1024 # 10MB
  
  module_function
  require 'date'
  require 'yaml'
  require 'json'
  require 'csv'
  require 'pathname'
  require 'faraday'
  require 'faraday/middleware'
  require '../propublica990/propublica990'
  require 'optparse'
  
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

  # Validate and sanitize API key input
  def validate_api_key(api_key)
    return false unless api_key.is_a?(String)
    return false if api_key.empty?
    return false if api_key.match?(/\[\]|\(|\{|\}|<|>|"|'|;|`|\$|&|\*|\||=/)
    true
  end

  # Safely load YAML with size and type checking
  def safe_load_yaml(file_path, max_size = MAX_FILE_SIZE)
    raise ArgumentError, "File path cannot be empty" if file_path.nil? || file_path.empty?
    
    # Validate path is within expected directory
    unless File.expand_path(file_path).start_with?(File.expand_path(Dir.pwd))
      raise SecurityError, "Attempt to load file outside working directory: #{file_path}"
    end
    
    # Check file size
    if File.size(file_path) > max_size
      raise ArgumentError, "File too large: #{file_path} (#{File.size(file_path)} bytes > #{max_size} bytes)"
    end
    
    # Parse with safe loading (no arbitrary code execution)
    YAML.safe_load(File.read(file_path), permitted_classes: [Date, Time])
  rescue => e
    raise LoadError, "Failed to load YAML from #{file_path}: #{e.message}"
  end

  # Get a list of all|current yaml data files of a type
  # @param dataType of yaml from DATA_DIRS
  # @param excludeField name of field to exclude if set (e.g. dissolved foundations) or nil
  # @return hash of meta => {}, dataType  => {identifier => data}, (exclude = {identifier => data})
  def get_dataset(dataType, excludeField = nil)
    raise(ArgumentError, "Invalid data type provided: #{dataType}") unless DATA_DIRS.key?(dataType)
    
    dataset = {META_KEY => {'method' => __method__.to_s, 'dataType' => dataType}, dataType => {}}
    
    # Validate data directory exists
    data_dir = DATA_DIRS[dataType]
    unless Dir.exist?(data_dir)
      raise ArgumentError, "Data directory does not exist: #{data_dir}"
    end
    
    Pathname.glob(File.join(data_dir, DATASET_EXT)) do |file|
      begin
        data = safe_load_yaml(file.to_s)
        if data.nil? || !data.is_a?(Hash) || !data.key?(IDENTIFIER_KEY)
          warn "Skipping invalid YAML file: #{file} (missing or invalid structure)"
          next
        end
        dataset[dataType][data[IDENTIFIER_KEY]] = data
      rescue => e
        warn "Error processing #{file}: #{e.message}"
        next
      end
    end
    
    if excludeField
      dataset[META_KEY]['excludeField'] = excludeField
      dataset[EXCLUDE_KEY], dataset[dataType] = dataset[dataType].partition { |k, v| v.has_key?(excludeField) }.map(&:to_h)
    end
    
    dataset
  end

  # Get a list of all available EINs (for US-based Nonprofit501c* only).
  # @param dir pointing to _foundations
  # @return array of strings of EINs
  def get_eins(dir)
    raise ArgumentError, "Directory path cannot be empty" if dir.nil? || dir.empty?
    
    unless Dir.exist?(dir)
      raise ArgumentError, "Directory does not exist: #{dir}"
    end
    
    eins = []
    Pathname.glob(File.join(dir, "*.md")) do |file|
      begin
        foundation = safe_load_yaml(file.to_s)
        next if foundation.nil?
        
        nonprofit = foundation['nonprofitStatus']
        if nonprofit && nonprofit.include?('Nonprofit501c')
          taxid = foundation['taxID']
          if taxid
            taxid = taxid.to_str.delete('-')
            if taxid.size == 9
              eins << taxid
            else
              warn "WARNING: missing/invalid taxID #{taxid} for #{foundation['identifier']}"
            end
          end
        end
      rescue => e
        warn "Error processing #{file}: #{e.message}"
        next
      end
    end
    
    eins.uniq # Remove duplicates
  end

  # Gather statistics on a single field in all foundations
  def gather_field(dir, onefield)
    raise ArgumentError, "Directory path cannot be empty" if dir.nil? || dir.empty?
    raise ArgumentError, "Field name cannot be empty" if onefield.nil? || onefield.empty?
    
    unless Dir.exist?(dir)
      raise ArgumentError, "Directory does not exist: #{dir}"
    end
    
    orgs = {}
    vals = Hash.new { |h, k| h[k] = [] }
    output = {'orgs' => orgs, 'vals' => vals}
    
    Dir.glob("#{dir}/*.md").each do |f|
      begin
        org = safe_load_yaml(f)
        next if org.nil?
        
        data = org.fetch(onefield, nil)
        identifier = File.basename(f, '.md')
        
        if data
          orgs[identifier] = data
          vals[data] << identifier
        else
          orgs[identifier] = "" # Include foundations with blanks explicitly
        end
      rescue => e
        warn "ERROR processing #{f}: #{e.message}"
        next # Otherwise ignore errors
      end
    end
    
    output
  end

  # Gather statistics on a multiple fields, selecting by first field for non-blank
  # @param dataset to evaluate
  # @param fieldList of fields to report out on; .first selects for non-blank
  def gather_fields(dataset, fieldList)
    raise ArgumentError, "Dataset cannot be empty" if dataset.nil? || dataset.empty?
    raise ArgumentError, "Field list cannot be empty" if fieldList.nil? || fieldList.empty?
    
    orgs = {}
    blankorgs = []
    output = {'orgs' => orgs, 'blanks' => blankorgs}
    
    dataset.each do |identifier, org|
      begin
        next if org.nil?
        
        tmp = {}
        fieldList.each do |f|
          tmp[f] = org.fetch(f, "")
        end
        
        if tmp[fieldList.first].to_s.empty?
          blankorgs << identifier
        else
          orgs[identifier] = tmp
        end
      rescue => e
        warn "ERROR processing #{identifier}: #{e.message}"
        next # Silently ignore errors
      end
    end
    
    output
  end

  # Report on field usage
  def field_usage(dataset)
    raise ArgumentError, "Dataset cannot be empty" if dataset.nil? || dataset.empty?
    
    report = {}
    report['orgs'] = []
    report['fieldcount'] = Hash.new(0)
    
    dataset.each do |org, hash|
      next if org.nil? || hash.nil?
      
      report['orgs'] << org
      hash.each do |k, v|
        report['fieldcount'][k] += 1 if v
      end
    end
    
    report['fieldcount'] = Hash[report['fieldcount'].sort_by { |k, v| -v }]
    report
  end

  # Report a set of fields for all active foundations
  # @param dataset to evaluate
  # @param fieldList of fields to report out on; .first selects for non-blank
  # @return hash of orgs and blanks with selected fields
  def foundation_fields(fieldList, csvfile = nil, jsonfile = nil)
    raise ArgumentError, "Field list cannot be empty" if fieldList.nil? || fieldList.empty?
    
    reportFields = fieldList + DEFAULT_FIELDS
    fdns = get_dataset('foundations', DISSOLUTION_DATE)
    report = gather_fields(fdns['foundations'], reportFields)
    
    orgs = report['orgs']
    blanks = report['blanks']
    
    puts "Active foundations: #{fdns['foundations'].size}, selection field: #{fieldList.first}, orgs with data/blanks: #{orgs.size} / #{blanks.size}"
    puts "Blank orgs: #{blanks.join(', ')}" unless blanks.empty?
    
    if jsonfile
      validate_and_write_file(jsonfile, JSON.pretty_generate(report))
    else
      puts JSON.pretty_generate(report)
    end
    
    if csvfile
      validate_file_path(csvfile, 'csv')
      CSV.open(csvfile, "w", force_quotes: true) do |csv|
        csv << ['identifier', *reportFields]
        orgs.each do |identifier, fields|
          csv << [identifier, *reportFields.map { |field| fields[field] }]
        end
      end
    end
  end

  # Validate file path and ensure it's safe to write
  def validate_file_path(path, expected_ext)
    raise ArgumentError, "Path cannot be empty" if path.nil? || path.empty?
    
    # Check for directory traversal
    if path.include?("..") || path.match?(/[\/]/)
      raise SecurityError, "Invalid path: #{path}"
    end
    
    # Check extension if provided
    if expected_ext && !path.downcase.end_with?(".#{expected_ext}")
      raise ArgumentError, "File must have .#{expected_ext} extension: #{path}"
    end
    
    # Ensure directory exists
    dir = File.dirname(path)
    unless Dir.exist?(dir) && File.writable?(dir)
      raise ArgumentError, "Directory does not exist or is not writable: #{dir}"
    end
  end

  # Safely write file with validation
  def validate_and_write_file(path, content)
    validate_file_path(path, 'json')
    
    # Check if file already exists
    if File.exist?(path)
      raise ArgumentError, "File already exists: #{path}"
    end
    
    # Write with atomic operation (create temp file, then rename)
    temp_path = "#{path}.tmp"
    File.open(temp_path, 'w') do |f|
      f.write(content)
    end
    
    File.rename(temp_path, path)
  rescue => e
    # Clean up temp file if it exists
    File.delete(temp_path) if File.exist?(temp_path)
    raise WriteError, "Failed to write file #{path}: #{e.message}"
  end

  # Fetch a full report of a single UK charity
  # @param registeredNumber of charity from taxID field
  # @param apiToken to access charitycommission.gov.uk
  # @return UK charities data combined hash
  def fetch_ukorg(registeredNumber, apiToken)
    raise ArgumentError, "Registered number cannot be empty" if registeredNumber.nil? || registeredNumber.empty?
    raise ArgumentError, "API token cannot be empty" if apiToken.nil? || apiToken.empty?
    
    unless validate_api_key(apiToken)
      raise SecurityError, "Invalid API key format"
    end
    
    org = {}
    ukCharities = 'https://api.charitycommission.gov.uk'
    
    # Configure Faraday with retry and timeout
    faraday = Faraday.new(url: ukCharities) do |config|
      config.response :raise_error
      config.response :json, content_type: /json$/
      config.adapter Faraday.default_adapter
      
      # Add retry middleware
      config.request :retry, 
                    max: MAX_RETRY_ATTEMPTS,
                    interval: 0.5,
                    backoff_factor: 2,
                    methods: [:get]
      
      # Add timeout
      config.options.timeout = REQUEST_TIMEOUT
      config.options.open_timeout = REQUEST_TIMEOUT
    end
    
    faraday.headers['Ocp-Apim-Subscription-Key'] = apiToken
    
    begin
      # Fetch organization details
      response = faraday.get("/register/api/allcharitydetailsV2/#{registeredNumber}/0")
      org['organization'] = response.body
      
      # Fetch financial history
      response = faraday.get("/register/api/charityfinancialhistory/#{registeredNumber}/0")
      org['filings'] = response.body
      
      # Parse and validate dates
      org['parseDate'] = DateTime.parse(org['organization']['last_modified_time'])
      
      org['data_source'] = ukCharities
      org['api_version'] = '2'
    rescue Faraday::Error => e
      raise FetchError, "Failed to fetch UK charity data: #{e.message}"
    end
    
    org
  end

  # Load secrets/API keys from a local file with validation
  # @param filename to read secrets from
  # @return relevant apikey TODO: generalize for other cases?
  def get_secrets(filename)
    raise ArgumentError, "Filename cannot be empty" if filename.nil? || filename.empty?
    
    # Validate path is safe
    full_path = File.expand_path(filename)
    unless full_path.start_with?(File.expand_path(Dir.pwd))
      raise SecurityError, "Attempt to load secrets file outside working directory: #{filename}"
    end
    
    unless File.exist?(full_path)
      raise ArgumentError, "Secrets file does not exist: #{filename}"
    end
    
    json = safe_load_yaml(full_path)
    raise ArgumentError, "Invalid secrets file format" unless json.is_a?(Hash) && json.key?('apikey')
    
    apikey = json['apikey']
    raise SecurityError, "Invalid API key in secrets file" unless validate_api_key(apikey)
    
    apikey
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
      opts.on('-lXYZ', '--fields x,y,z', Array, 'Report on a custom list of fields (plus DEFAULT_FIELDS).') do |fieldList|
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
    
    options
  end
end

# ### #### ##### ######
# Main method for command line use
if __FILE__ == $PROGRAM_NAME
  begin
    options = FoundationReporter.parse_commandline
    fieldList = options.fetch(:fieldList, [])
    
    if fieldList.size > 0
      FoundationReporter.foundation_fields(fieldList, options[:out])
      exit 0
    end

    ukorg = options.fetch(:ukorg, nil)
    if ukorg
      begin
        outfile = File.join(FoundationReporter::DATA_DIRS['taxes'], "uk-#{ukorg}.json")
        api_key = FoundationReporter.get_secrets('../fossfoundation-api.json')
        output = FoundationReporter.fetch_ukorg(ukorg, api_key)
        
        # Validate and write output file
        FoundationReporter.validate_and_write_file(outfile, JSON.pretty_generate(output))
        puts "Done, wrote out: #{outfile}"
      rescue => e
        $stderr.puts "Error fetching UK charity data: #{e.message}"
        exit 1
      end
      
      exit 0
    end

    ctype = options.fetch(:ctype, nil)
    if ctype
      begin
        dataset = FoundationReporter.get_dataset(ctype)
        output = FoundationReporter.field_usage(dataset[ctype])
        puts JSON.pretty_generate(output)
      rescue => e
        $stderr.puts "Error processing dataset: #{e.message}"
        exit 1
      end
    end

    ctype ||= 'foundations'
    onefield = options.fetch(:onefield, nil)
    if onefield
      begin
        output = FoundationReporter.gather_field(FoundationReporter::DATA_DIRS[ctype], onefield)
        puts JSON.pretty_generate(output)
      rescue => e
        $stderr.puts "Error gathering field data: #{e.message}"
        exit 1
      end
    end

    reports = options.fetch(:reports, nil)
    options[:out] ||= 'foundations_990_common.csv'
    
    if reports
      begin
        eins = FoundationReporter.get_eins(FoundationReporter::DATA_DIRS['foundations'])
        orgs = Propublica990.get_orgs(eins, FoundationReporter::DATA_DIRS['p990'], refresh: true)
        report_csv = File.join(FoundationReporter::DATA_DIRS['p990'], options[:out])
        Propublica990.orgs2csv_common(orgs, report_csv)
      rescue => e
        $stderr.puts "Error generating reports: #{e.message}"
        exit 1
      end
    end
  rescue => e
    $stderr.puts "Fatal error: #{e.message}"
    exit 1
  end
end