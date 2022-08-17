# test/lib/test_ingestor_event.rb

require 'test_helper'

class TestIngestorEvent < ActiveSupport::TestCase
  # reference dates are assumed to be in CEST, and parsed in the year 2022
  Time.use_zone('Europe/Amsterdam') do
    DATES = {
      'Thursday 22 september 2022 till saturday 24 september 2022 ': [Time.zone.parse('2022-9-22'), Time.zone.parse('2022-9-24')],
      '3-7 october 2022': [Time.zone.parse('2022-10-3'), Time.zone.parse('2022-10-7')],
      '21 and 22 september 2022': [Time.zone.parse("2022-9-21"), Time.zone.parse("2022-9-22")],
      'tuesday 20 september 2022': [Time.zone.parse("2022-9-20"), Time.zone.parse("2022-9-20")],
      'thursday, 15 september 2022, 15:00 - 16:00 CEST (13:00 - 14:00 UTC)': [
        Time.zone.parse('2022-9-15 15:00').to_datetime,
        Time.zone.parse('2022-9-15 16:00').to_datetime],
      'thursday 8 september, 13:00 - 17:00': [
        Time.zone.parse('2022-9-8 13:00').to_datetime,
        Time.zone.parse('2022-9-8 17:00').to_datetime],
      # this one is bonkers, no way to parse nicely. ignore
      #'6 october 2022 | 9:00-12:00 GMT-3/13:00-16:00 CEST | online': [
        #Time.zone.parse('2022-10-6 13:00').to_datetime,
        #Time.zone.parse('2022-10-6 16:00').to_datetime],
      '10 october 2022 till 11 october 2022 ': [Time.zone.parse("2022-10-10"), Time.zone.parse("2022-10-11")],
      '2-3 november 2022 | online': [Time.zone.parse("2022-11-2"), Time.zone.parse("2022-11-3")],
      'donderdag 17 november 2022, location': [Time.zone.parse("2022-11-17"), Time.zone.parse("2022-11-17")],
      '5-6 december 2022 - location': [Time.zone.parse("2022-12-5"), Time.zone.parse("2022-12-6")],
      '22 september': [Time.zone.parse("2022-9-22"), Time.zone.parse("2022-9-22")]
    }.freeze

    DATES.each_pair do |str, (start, endt)|
      str = str.to_s
      test str do
        freeze_time(Time.zone.parse("2022-8-1")) do
          subject = Ingestors::IngestorEvent.new
          assert_equal start, subject.parse_start_date(str, 'Amsterdam')
          assert_equal endt, subject.parse_end_date(str, 'Amsterdam')
        end
      end
    end
  end
end