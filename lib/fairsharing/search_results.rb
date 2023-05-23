# frozen_string_literal: true

module Fairsharing
  class SearchResults < Array
    attr_accessor :page, :first_page, :prev_page, :next_page, :last_page

    def self.from_api_response(hash)
      results = new(hash['data'])
      hash['links'].each do |key, value|
        value = value&.split('?')&.last
        next unless value

        page_number = Rack::Utils.parse_nested_query(value).dig('page', 'number')&.to_i
        next unless page_number

        case key
        when 'self'
          results.page = page_number
        when 'first'
          results.first_page = page_number
        when 'prev'
          results.prev_page = page_number
        when 'next'
          results.next_page = page_number
        when 'last'
          results.last_page = page_number
        end
      end
      results
    end
  end
end
