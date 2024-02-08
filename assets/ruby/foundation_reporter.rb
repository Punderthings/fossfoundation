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
end

# ### #### ##### ######
# Main method for command line use
if __FILE__ == $PROGRAM_NAME
  foundation_dir = File.join(Dir.pwd, '_foundations')
  report_dir = File.join(Dir.pwd, '_data/p990')
  eins = FoundationReporter.get_eins(foundation_dir)
  orgs = Propublica990.get_orgs(eins, report_dir)
  report_csv = File.join(report_dir, "foundations_990_common.csv")
  Propublica990.orgs2csv_common(orgs, report_csv)
end
