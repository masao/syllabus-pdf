#!/usr/bin/env ruby

require "roo"
require "combine_pdf"

if ARGV[0].nil? or not File.exist? ARGV[0]
  puts "Usage: #$0 file.xlsx"
  exit
end

output = CombinePDF.new
xlsx = Roo::Excelx.new(ARGV[0])
xlsx.each_row_streaming(pad_cells: true) do |row|
  subject_id = row[2].value
  if subject_id.to_s =~ /^[0-9A-Z]/
    p subject_id
    subject_name = row[3].value
    filename = row[13]&.value
    if filename and not filename.to_s.empty?
      page_offset = row[14].value
      page_length = row[15].value
      pdf = CombinePDF.load(filename)
      output << pdf.pages[page_offset-1, page_length]
    end
  end
end
output.save("syllabus.pdf")
