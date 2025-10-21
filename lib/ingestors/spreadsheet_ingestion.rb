module Ingestors
  module SpreadsheetIngestion
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
      row[header].to_s.lstrip.split(/;/).reject(&:empty?).compact unless row[header].nil?
    end

    def get_column(row, header)
      row[header].to_s.lstrip unless row[header].nil?
    end

    # if url is a raw google spreadsheet
    # it returns the Google spreadsheet CSV export
    # else it returns the url
    def gsheet_to_csv(url)
      return url unless url.include? 'docs.google.com/spreadsheets/d/'

      spreadsheet_id = url.partition('d/').last.partition('/').first
      gid = CGI.parse(URI.parse(url).query)['gid']&.first
      "https://docs.google.com/spreadsheets/d/#{spreadsheet_id}/export?gid=#{gid}&exportFormat=csv"
    end
  end
end
