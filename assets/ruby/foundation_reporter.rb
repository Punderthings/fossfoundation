#!/usr/bin/env ruby
module FoundationReporter
  DESCRIPTION = <<-HEREDOC
  FoundationReporter: Various reporting utilities.
  HEREDOC
  module_function
  require 'yaml'
  require 'json'
  require 'csv'
  require 'pathname'
  require '../propublica990/propublica990'
  require 'optparse'

  # Get a list of all foundation files
  # @param dir pointing to _foundations
  # @return hash of org => yaml frontmatter hash
  def get_foundations(dir)
    foundations = {}
    Pathname.glob(File.join(dir, "*.md")) do |file|
      foundation = YAML.load_file(file)
      foundations[foundation['identifier']] = foundation
    end
    return foundations
  end

  # Get a list of all yaml data files of a type
  # @param dir pointing to _foundations, _sponsorships, etc.
  # @return hash of org => yaml frontmatter hash
  def get_yamldataset(dir)
    datasets = {}
    Pathname.glob(File.join(dir, "*.md")) do |file|
      dataset = YAML.load_file(file)
      datasets[dataset['identifier']] = dataset
    end
    return datasets
  end

  # Get a list of all available EINs (for US-based Nonprofit501c* only).
  # @param dir pointing to _foundations
  # @return array of strings of EINs
  def get_eins(dir)
    eins = []
    Pathname.glob(File.join(dir, "*.md")) do |file|
      foundation = YAML.load_file(file)
      nonprofit = foundation['nonprofitStatus']
      if nonprofit.include?('Nonprofit501c')
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
  def gather_field(dir, onefield)
    orgs = {}
    vals = Hash.new{ | h, k | h[k] = [] }
    output = {'orgs' => orgs, 'vals' => vals}
    Dir["#{dir}/*.md"].each do |f|
      begin
        org = YAML.load_file(f)
        data = org.fetch(onefield, nil)
        if data
          identifier = File.basename(f, '.md')
          orgs[identifier] = data
          vals[data] << identifier
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

  # ## ### #### ##### ######
  # Check commandline options
  def parse_commandline
    options = {}
    OptionParser.new do |opts|
      opts.on('-h', '--help') { puts "#{DESCRIPTION}\n#{opts}"; exit }
      opts.on('-oOUTFILE', '--out OUTFILE', 'Output filename for operation') do |out|
        options[:out] = out
      end
      opts.on('-iINFILE', '--in INFILE', 'Input filename for operation') do |infile|
        options[:infile] = infile
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
  options[:outfile] ||= 'foundation_reporter.json'

  dirs = {
    'foundations' => File.join(Dir.pwd, '_foundations'),
    'sponsorships' => File.join(Dir.pwd, '_sponsorships'),
    'entities' => File.join(Dir.pwd, '_entities'),
    'p990' => File.join(Dir.pwd, '_data/p990')
  }

  ctype = options.fetch(:ctype, nil)
  if ctype
    output = {}
    dataset = FoundationReporter.get_yamldataset(dirs[ctype])
    output = FoundationReporter.field_usage(dataset)
    puts JSON.pretty_generate(output)
  end

  ctype ||= 'foundations'
  onefield = options.fetch(:onefield, nil)
  if onefield
    output = {}
    output = FoundationReporter.gather_field(dirs[ctype], onefield)
    puts JSON.pretty_generate(output)
  end

  reports = options.fetch(:reports, nil)
  if reports

    eins = FoundationReporter.get_eins(foundation_dir)
    orgs = Propublica990.get_orgs(eins, p990_dir)
    report_csv = File.join(p990_dir, options[:outfile])
    Propublica990.orgs2csv_common(orgs, report_csv)
  end
end
