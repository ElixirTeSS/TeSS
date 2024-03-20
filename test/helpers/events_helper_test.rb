# frozen_string_literal: true

require 'test_helper'

class EventsHelperTest < ActionView::TestCase
  test 'neatly_printed_date_range' do
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
end
