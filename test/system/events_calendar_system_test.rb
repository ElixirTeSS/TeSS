require 'application_system_test_case'

class EventsCalendarSystemTest < ApplicationSystemTestCase
  test 'calendar tab loads and renders events with javascript' do
    freeze_time(Time.utc(2026, 5, 20, 12, 0, 0)) do
      Event.order(:id).first!.update!(
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

      visit events_path

      within('.index-display-options') { click_link 'Calendar' }

      assert_selector('#events_calendar #calendar.simple-calendar')
      assert_selector('#events_calendar a.clear-both', text: 'System calendar event')
    end
  end
end
