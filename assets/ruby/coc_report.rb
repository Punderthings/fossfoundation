#!/usr/bin/env ruby
module COCReports
  DESCRIPTION = <<-HEREDOC
  COCReports: Dump statistics on use of Codes of Conduct in FossFoundation datasets.
  HEREDOC
  module_function
  require 'csv'
  require_relative 'foundation_reporter.rb'

  CONDUCT_FIELDS = %w[conducturl conductSource conductLinked conductEvents conductReport]
  WITHCOC_SPAN = "<span class='text-blue-200'>"
  WITHOUTCOC_SPAN = "<span class='text-green-200'>"

  # Return one line markdown report of COC fields
  def emit_org(org)
    line = "[#{org['commonName']}](#{org['conducturl']})"
    line << ", COC linked from: #{org['conductLinked']}" unless org['conductLinked'].to_s.empty? || 'x'.eql?(org['conductLinked'])
    line << ", event-specific COC: #{org['conductEvents']}" unless org['conductEvents'].to_s.empty?
    line << ", *inspired by: #{org['conductSource']}*" unless org['conductSource'].to_s.empty?
    return line
  end

  # Reminder to self: https://kramdown.gettalong.org/syntax.html#html-blocks
  def emit_section(id)
    return "<section id='#{id}' markdown='1'>\n"
  end

  # Emit comparison of two sets of foundations
  def emit_comparison(withcoc, withoutcoc, subtitle)
    allsize = withcoc.size + withoutcoc.size
    lines = "### #{subtitle} Foundations count: #{allsize}\n\n"
    lines << "{: .text-blue-200}\n#### #{subtitle} With a COC:  #{withcoc.size}  (#{sprintf('%.f', withcoc.size.to_f / allsize * 100)}%)\n\n"
    withcoc.each do |k, v|
      lines << "- #{emit_org(v)}\n"
    end
    lines << "\n{: .text-green-200}\n#### #{subtitle} With**out** COC: #{withoutcoc.size}  (#{sprintf('%.f', withoutcoc.size.to_f / allsize * 100)}%)\n\n"
    withoutcoc.each do |k, v|
      lines << "- #{v['commonName']}\n"
    end
    lines << "\n"
    return lines
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
    markdown << emit_section('dataset-size')
    markdown << "## Dataset Size\n\n"
    markdown << "- Total foundations: #{foundations.size + dataset[FoundationReporter::EXCLUDE_KEY].size}\n"
    markdown << "- Dissolved foundations: #{dataset[FoundationReporter::EXCLUDE_KEY].size}\n"
    markdown << "  - #{dataset[FoundationReporter::EXCLUDE_KEY].keys.join(', ')}\n"
    markdown << "- Active foundations: #{foundations.size}\n"
    markdown << "  - #{WITHCOC_SPAN}With a COC:  #{withcoc.size}  (#{sprintf('%.f', withcoc.size.to_f / foundations.size * 100)}%)</span>\n"
    markdown << "  - #{WITHOUTCOC_SPAN}With**out** COC: #{withoutcoc.size}  (#{sprintf('%.f', withoutcoc.size.to_f / foundations.size * 100)}%)</span>\n\n"
    markdown << "</section>\n"

    c3, nonc3 = foundations.partition { |k, v| 'Nonprofit501c3'.eql?(v['nonprofitStatus']) }.map(&:to_h)
    c6, otherFdn = nonc3.partition { |k, v| 'Nonprofit501c6'.eql?(v['nonprofitStatus']) }.map(&:to_h)
    c3withoutcoc, c3withcoc = c3.partition { |k, v| v['conducturl'].to_s.empty? }.map(&:to_h)
    c6withoutcoc, c6withcoc = c6.partition { |k, v| v['conducturl'].to_s.empty? }.map(&:to_h)
    markdown << "* * *\n"

    markdown << emit_section('nonprofitStatus')
    markdown << "## COC Use By Nonprofit Status\n\n"
    markdown << "Comparison of US-based c3 versus c6 foundation uses of COCs.\n\n"
    markdown << emit_comparison(c3withcoc, c3withoutcoc, '501(c)(3)')
    markdown << emit_comparison(c6withcoc, c6withoutcoc, '501(c)(6)')
    markdown << "### All other foundations count: #{otherFdn.size}\n\n"
    otherFdn.each do |k, v|
      markdown << "- #{emit_org(v)}\n"
    end
    markdown << "\n"
    markdown << "</section>\n\n"

    markdown << "* * *\n\n"
    markdown << emit_section('inspiration')
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
  output << "layout: report\n"
  output << "parent: Reports\n"
  output << "generator: #{$PROGRAM_NAME}\n"
  output << "---\n\n"
  output << COCReports.coc2markdown()
  output << "\nMore resources: [Open Source Codes of Conduct review](https://opensourceconduct.com/)."
  fname = File.join(Dir.pwd, "_reports", "coc.md")
  File.open(fname, "w") { |f| f.write output }
  puts "DONE: wrote #{fname}"
end
