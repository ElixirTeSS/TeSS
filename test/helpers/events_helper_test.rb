require 'test_helper'

class EventsHelperTest < ActionView::TestCase

  test "neatly_printed_date_range" do
    assert_equal '15 April 2023',
                 neatly_printed_date_range(DateTime.new(2023, 4, 15, 0)),
                 'Should display single date without time if time is midnight'

    assert_equal '15 April 2023',
                 neatly_printed_date_range(DateTime.new(2023, 4, 15, 0), DateTime.new(2023, 4, 15, 0)),
                 'Should display single date without time if time is midnight'

    assert_equal '15 April 2023 @ 09:00',
                 neatly_printed_date_range(DateTime.new(2023, 4, 15, 9)),
                 'Should display single date with single time if no finish date'

    assert_equal '15 April 2023 @ 09:00',
                 neatly_printed_date_range(DateTime.new(2023, 4, 15, 9), DateTime.new(2023, 4, 15, 9)),
                 'Should display single date with single time if both start and finish are the same'

    assert_equal '15 April 2023 @ 09:00 - 17:00',
                 neatly_printed_date_range(DateTime.new(2023, 4, 15, 9), DateTime.new(2023, 4, 15, 17)),
                 'Should display single date with time range'

    assert_equal '15 April 2023 @ 00:00 - 00:15',
                 neatly_printed_date_range(DateTime.new(2023, 4, 15, 0, 0), DateTime.new(2023, 4, 15, 0, 15)),
                 'Should display single date with time range if at least one time is not midnight'

    assert_equal '15 April 2023 @ 09:15 - 09:16',
                 neatly_printed_date_range(DateTime.new(2023, 4, 15, 9, 15), DateTime.new(2023, 4, 15, 9, 16)),
                 'Should display single date with time range'

    assert_equal '15 April 2023 @ 09:15 - 21:15',
                 neatly_printed_date_range(DateTime.new(2023, 4, 15, 9, 15), DateTime.new(2023, 4, 15, 21, 15)),
                 'Should display single date with time range'

    assert_equal '15 - 16 April 2023',
                 neatly_printed_date_range(DateTime.new(2023, 4, 15, 9), DateTime.new(2023, 4, 16, 17)),
                 'Should display date range without time'

    assert_equal '15 April - 16 May 2023',
                 neatly_printed_date_range(DateTime.new(2023, 4, 15, 9), DateTime.new(2023, 5, 16, 17)),
                 'Should display date and month range without time'

    assert_equal '15 April 2023 - 16 May 2024',
                 neatly_printed_date_range(DateTime.new(2023, 4, 15, 9), DateTime.new(2024, 5, 16, 17)),
                 'Should display date, month and year range without time'

    assert_equal '15 April 2023 - 16 May 2024',
                 neatly_printed_date_range(DateTime.new(2023, 4, 15), DateTime.new(2024, 5, 16)),
                 'Should display date, month and year range without time'

    assert_equal 'No date given', neatly_printed_date_range('', '')
    assert_equal 'No date given', neatly_printed_date_range(nil, '')
    assert_equal 'No start date', neatly_printed_date_range(nil, DateTime.new(2024, 5, 16, 17))
  end

  test 'google calendar export in UTC with the IANA time zone when the time zone is known' do
    event = events(:one)
    event.assign_attributes(timezone: 'Perth', start: Time.utc(2022, 2, 11, 9, 45), end: Time.utc(2022, 2, 11, 12, 50))
    params = Rack::Utils.parse_query(URI.parse(google_calendar_export_url(event)).query)
    assert_equal '20220211T014500Z/20220211T045000Z', params['dates']
    assert_equal 'Australia/Perth', params['ctz']
  end

  test 'google calendar export in local time when the time zone is unknown' do
    event = events(:one)
    event.assign_attributes(timezone: nil, start: Time.utc(2026, 11, 5, 9), end: Time.utc(2026, 11, 5, 17))
    params = Rack::Utils.parse_query(URI.parse(google_calendar_export_url(event)).query)
    assert_equal '20261105T090000/20261105T170000', params['dates']
    assert_nil params['ctz']
  end
end
