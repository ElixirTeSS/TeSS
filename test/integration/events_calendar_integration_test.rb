require 'test_helper'

class EventsCalendarIntegrationTest < ActionDispatch::IntegrationTest
  test 'calendar page loads and renders event calendar' do
    freeze_time(Time.utc(2026, 5, 20, 12, 0, 0)) do
      Event.create!(
        title: 'System calendar event',
        url: 'http://example.com/system-calendar-event',
        user: users(:regular_user),
        content_provider: content_providers(:goblet),
        timezone: 'UTC',
        start: Time.now.beginning_of_month + 10.days,
        end: Time.now.beginning_of_month + 10.days + 2.hours,
        city: 'Manchester',
        country: 'United Kingdom'
      )

      get calendar_events_path

      assert_response :success
      assert_select '#events-calendar #calendar.simple-calendar'
      assert_select '#events-calendar table.table.table-striped'
      assert_select '#events-calendar a.clear-both', text: 'System calendar event'
    end
  end
end
