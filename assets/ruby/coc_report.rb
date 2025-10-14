#!/usr/bin/env ruby
module COCReports
  DESCRIPTION = <<-HEREDOC
  COCReports: Dump statistics on use of Codes of Conduct in FossFoundation datasets.
  HEREDOC
  module_function
  require 'csv'
  require_relative 'foundation_reporter.rb'

  CONDUCT_FIELDS = %w[conducturl conductSource conductLinked conductEvents conductReport]

  # Return one line markdown report of COC fields
  def emit_org(org)
    line = "[#{org['commonName']}](#{org['conducturl']})"
    line << ", COC linked from: #{org['conductLinked']}" unless org['conductLinked'].to_s.empty? || 'x'.eql?(org['conductLinked'])
    line << ", event-specific COC: #{org['conductEvents']}" unless org['conductEvents'].to_s.empty?
    line << ", *inspired by: #{org['conductSource']}*" unless org['conductSource'].to_s.empty?
    return line
  end

  # Dump a simple report of Codes of Conduct as markdown
  def coc2markdown()
    fieldList = CONDUCT_FIELDS + FoundationReporter::DEFAULT_FIELDS
    dataset = FoundationReporter.get_dataset('foundations', FoundationReporter::DISSOLUTION_DATE)
    foundations = dataset['foundations']
    withcoc = {}
    withoutcoc = {}
    foundations.each do |identifier, org|
      tmp = {}
      fieldList.each do |f|
        tmp[f] = org.fetch(f, "")
      end
      if tmp[fieldList.first].to_s.empty?
        withoutcoc[identifier] = tmp
      else
        withcoc[identifier] = tmp
      end
    end
    markdown = "[Dataset Size](#dataset-size) | [Nonprofit Type](#nonprofitStatus) | [Inspiration](#inspiration)\n\n"
    markdown << "<section id='dataset-size'>\n\n"
    markdown << "## Dataset Size\n\n"
    markdown << "- Total foundations: #{foundations.size + dataset[FoundationReporter::EXCLUDE_KEY].size}\n"
    markdown << "- Dissolved foundations: #{dataset[FoundationReporter::EXCLUDE_KEY].size}\n"
    markdown << "  - #{dataset[FoundationReporter::EXCLUDE_KEY].keys.join(', ')}\n"
    markdown << "- Active foundations: #{foundations.size}\n"
    markdown << "  - With a COC:  #{withcoc.size}  (#{sprintf('%.f', withcoc.size.to_f / foundations.size * 100)}%)\n"
    markdown << "  - With**out** COC: #{withoutcoc.size}  (#{sprintf('%.f', withoutcoc.size.to_f / foundations.size * 100)}%)\n\n"
    markdown << "</section>\n\n"

    c3, nonc3 = foundations.partition { |k, v| 'Nonprofit501c3'.eql?(v['nonprofitStatus']) }.map(&:to_h)
    c6, otherFdn = nonc3.partition { |k, v| 'Nonprofit501c6'.eql?(v['nonprofitStatus']) }.map(&:to_h)
    c3withoutcoc, c3withcoc = c3.partition { |k, v| v['conducturl'].to_s.empty? }.map(&:to_h)
    c6withoutcoc, c6withcoc = c6.partition { |k, v| v['conducturl'].to_s.empty? }.map(&:to_h)
    markdown << "* * *\n\n"
    markdown << "<section id='nonprofitStatus'>\n\n"
    markdown << "## COC Use By Nonprofit Status\n\n"
    markdown << "Comparison of US-based c3 versus c6 foundation uses of COCs.\n\n"
    markdown << "### 501(c)(3) foundations count: #{c3.size}\n\n"
    markdown << "#### C3s With a COC:  #{c3withcoc.size}  (#{sprintf('%.f', c3withcoc.size.to_f / c3.size * 100)}%)\n\n"
    c3withcoc.each do |k, v|
      markdown << "- #{emit_org(v)}\n"
    end
    markdown << "\n"
    markdown << "#### C3s With**out** COC: #{c3withoutcoc.size}  (#{sprintf('%.f', c3withoutcoc.size.to_f / c3.size * 100)}%)\n\n"
    c3withoutcoc.each do |k, v|
      markdown << "- #{v['commonName']}\n"
    end
    markdown << "\n"
    markdown << "### 501(c)(6) foundations count: #{c6.size}\n\n"
    markdown << "#### C6s With a COC:  #{c6withcoc.size}  (#{sprintf('%.f', c6withcoc.size.to_f / c6.size * 100)}%)\n\n"
    c6withcoc.each do |k, v|
      markdown << "- #{emit_org(v)}\n"
    end
    markdown << "\n"
    markdown << "#### C6s With**out** COC: #{c6withoutcoc.size}  (#{sprintf('%.f', c6withoutcoc.size.to_f / c6.size * 100)}%)\n\n"
    c6withoutcoc.each do |k, v|
      markdown << "- #{v['commonName']}\n"
    end
    markdown << "\n"
    markdown << "### All other foundations count: #{otherFdn.size}\n\n"
    otherFdn.each do |k, v|
      markdown << "- #{emit_org(v)}\n"
    end
    markdown << "\n"
    markdown << "</section>\n\n"

    markdown << "* * *\n\n"
    markdown << "<section id='inspiration'>\n\n"
    markdown << "## COCs By Inspiration Documents\n\n"
    markdown << "Codes of Conduct are often inspired by existing docs like the [Contributor Covenant](https://www.contributor-covenant.org/). This section lists COCs when an organization specifically lists an inspiration.\n\n"
    inspired = []
    withcoc.each do |k, v|
      next if v['conductSource'].to_s.empty?
      inspired << "- #{emit_org(v)}\n" if v['conductSource'].to_s.downcase.include?('covenant')
    end
    markdown << "### Inspired by Contributor Covenant: (#{inspired.count})\n\n"
    markdown << inspired.join()
    markdown << "\n"
    inspired = []
    withcoc.each do |k, v|
      next if v['conductSource'].to_s.empty?
      inspired << "- #{emit_org(v)}\n" unless v['conductSource'].to_s.downcase.include?('covenant')
    end
    markdown << "### Inspired by Other Sources: (#{inspired.count})\n\n"
    markdown << inspired.join()
    markdown << "\n"
    inspired = []
    withcoc.each do |k, v|
      next unless v['conductSource'].to_s.empty?
      inspired << "- #{emit_org(v)}\n"
    end
    markdown << "### No Inspiration Mentioned: (#{inspired.count})\n\n"
    markdown << inspired.join()
    markdown << "\n"
    markdown << "</section>\n\n"

    return markdown
  end
end

# ### #### ##### ######
# Main method for command line use
if __FILE__ == $PROGRAM_NAME
  output = "---\n"
  output << "title: Codes Of Conduct\n"
  output << "excerpt: Code of Conduct Use By Foundations.\n"
  output << "layout: reports\n"
  output << "parent: Reports\n"
  output << "---\n\n"
  output << COCReports.coc2markdown()
  fname = File.join(Dir.pwd, "_reports", "coc.md")
  File.open(fname, "w") { |f| f.write output }
  puts "DONE: wrote #{fname}"
end
