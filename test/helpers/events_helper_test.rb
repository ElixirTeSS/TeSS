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

  test 'approval_options_for_select_event returns mapped array of translated pairs' do
    options = approval_options_for_select_event

    assert_kind_of Array, options
    assert_equal Event::APPROVAL_STATUS.values.size, options.size

    Event::APPROVAL_STATUS.values.each do |status|
      expected_label = I18n.t("events.approval_status.#{status}")
      assert_includes options, [expected_label, status]
    end
  end

  test 'event_enabled_badge renders success label when true' do
    badge = event_enabled_badge(true)

    assert_dom_equal '<span class="label label-success">Enabled</span>', badge
  end

  test 'event_enabled_badge renders danger label when false' do
    badge = event_enabled_badge(false)

    assert_dom_equal '<span class="label label-danger">Disabled</span>', badge
  end

  test 'event_approval_badge renders correct labels for each status' do
    statuses = {
      not_approved: 'label-danger',
      requested: 'label-warning',
      approved: 'label-success'
    }

    statuses.each do |status, expected_class|
      label_text = I18n.t("events.approval_status.#{status}")
      
      [status, status.to_s].each do |input|
        badge = event_approval_badge(input)
        assert_dom_equal "<span class=\"label #{expected_class}\">#{label_text}</span>", badge
      end
    end
  end

  test 'event_approval_badge returns nil for unknown status' do
    assert_nil event_approval_badge(:unknown_status)
  end
end
