module Ingestors
  module CsvIngestion
    def process_url(row, header)
      row[header].to_s.lstrip unless row[header].nil?
    end

    def process_description(row, header)
      return nil if row[header].nil?

      desc = row[header]
      desc.gsub!(/""/, '"')
      desc.gsub!(/\A""|""\Z/, '')
      desc.gsub!(/\A"|"\Z/, '')
      convert_description desc
    end

    def process_array(row, header)
      # split by: comma or semicolon, optionally surrounded by whitespace
      # or two or more whitespace characters
      # any number of newline characters
      split_regex = /\s*[,;]\s*|\s{2,}|[\r\n]+/x
      row[header].to_s.lstrip.split(split_regex).reject(&:empty?).compact unless row[header].nil?
    end

    def get_column(row, header)
      row[header].to_s.lstrip unless row[header].nil?
    end
  end
end
