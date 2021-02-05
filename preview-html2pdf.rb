#!/usr/bin/env ruby

require "nokogiri"

class Nokogiri::XML::NodeSet
  def val
    self.first&.inner_html&.escape_tex
  end
end
class String
  def escape_tex
    self.strip.gsub(/<BR>\Z/i, "").gsub(/<BR>/i, "\\par ").gsub(/_/, "\\_").gsub(/~/, "～")
  end
end

def html2longtable(doc)
  names = {}
  %i[ course title credit grade assignments timetable ].each do |attr|
    attr_value = doc.xpath("//span[@id='#{attr}']").val
    attr_value.gsub!(/,/, "") if attr == :grade or attr == :timetable or attr == :credit
    names[attr] = attr_value
  end
  result = <<EOF
\\noindent
\\begin{longtable}{|p{10zw}|p{42zw}|}
\\hline
授業科目名 & #{names[:title]}\\\\\\hline
科目番号 & #{names[:course]}\\\\\\hline
単位数 & #{names[:credit]}\\\\\\hline
標準履修年次 & #{names[:grade]}\\\\\\hline
時間割 & #{names[:timetable]}\\\\\\hline
担当教員 & #{names[:assignments]}\\\\\\hline
EOF
  %w( summary-heading-summary-contents note-heading-note style-heading-style ).each do |element|
    doc.xpath("//div[@id='#{element}']").each do |content|
      name = content.xpath("./h2").val
      value = content.xpath("./p").val
      topic = content.xpath("./div[@id='topics']").first
      if topic
        value = ""
        topic.xpath("./p[@id='pretopics']").each do |e|
          value << e.inner_html.escape_tex
          value << "\n\n"
        end
        rows = []
        topic.xpath(".//table/tr").each do |tr|
          num = tr.xpath("./th").val
          val = tr.xpath("./td").val
          if val.empty?
            rows << "&#{num}"
          else
            rows << "#{num} & #{val}"
          end
        end
        if not rows.empty?
          value << <<-EOF
          \\noindent\\begin{tabular}{lp{36zw}}
          #{rows.join("\\\\\n")}
          \\end{tabular}
          EOF
        end
      end
      if value and not value.empty?
        result << <<-EOF
        #{name} & #{value.strip}\\\\\\hline
        EOF
      end
    end
  end
  divs = doc.xpath("//div")
  divs.each do |div|
    id = div["id"]
    if id
      name = div.xpath("./h2").first&.content
      content = div.xpath("./p").first&.content
      STDERR.puts [id, name, content].inspect
    end
  end
  result << "\\end{longtable}\\newpage"
  result
end

latex = <<'EOF'
\documentclass[a4j]{jsarticle}
\usepackage{longtable}
\usepackage[top=10truemm,bottom=15truemm,left=18truemm,right=20truemm]{geometry}
\pagestyle{empty}
\begin{document}
EOF
ARGV.each do |f|
  doc = Nokogiri::HTML(open(f))
  latex << html2longtable(doc)
end
latex << "\\end{document}"
puts latex
