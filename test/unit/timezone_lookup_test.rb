# frozen_string_literal: true

require 'test_helper'

class TimezoneLookupTest < ActiveSupport::TestCase
  test 'finds time zone from coordinates' do
    assert_equal 'Melbourne', TimezoneLookup.find(latitude: -37.81, longitude: 144.96)
    assert_equal 'Perth', TimezoneLookup.find(latitude: -31.95, longitude: 115.86)
    assert_equal 'Mountain Time (US & Canada)', TimezoneLookup.find(latitude: 43.6, longitude: -116.2) # Boise
  end

  test 'finds time zone from coordinates near a time zone border' do
    # Evansville, Indiana is on Central time, although the nearest time zone city (Petersburg, Indiana) is Eastern
    assert_equal 'Central Time (US & Canada)', TimezoneLookup.find(latitude: 37.97, longitude: -87.57)
  end

  test 'prefers the time zone name of the city' do
    assert_equal 'London', TimezoneLookup.find(latitude: 51.5, longitude: -0.12)
    assert_equal 'London', TimezoneLookup.find(latitude: 55.95, longitude: -3.19) # Edinburgh is also Europe/London
  end

  test 'gives a time zone with the same offsets when TeSS has no name for it' do
    # Atlantic/Canary is not one of the Rails time zones, but has the same offsets as Lisbon
    assert_equal 'Lisbon', TimezoneLookup.find(latitude: 28.12, longitude: -15.43)
  end

  test 'coordinates take precedence over country' do
    assert_equal 'Moscow', TimezoneLookup.find(latitude: 45, longitude: 45, country: 'United Kingdom')
  end

  test 'finds time zone from country with a single time zone' do
    assert_equal 'London', TimezoneLookup.find(country: 'United Kingdom')
    assert_equal 'London', TimezoneLookup.find(country: 'GB')
    assert_equal 'Berlin', TimezoneLookup.find(country: 'Germany') # also has Europe/Busingen, with the same offsets
  end

  test 'no time zone for country with several time zones' do
    assert_nil TimezoneLookup.find(country: 'United States')
    assert_nil TimezoneLookup.find(country: 'Spain') # Canary Islands are an hour behind
  end

  test 'no time zone without location' do
    assert_nil TimezoneLookup.find
    assert_nil TimezoneLookup.find(country: '')
    assert_nil TimezoneLookup.find(country: 'BigCountry')
    assert_nil TimezoneLookup.find(latitude: 0, longitude: -30) # Atlantic ocean
  end

  test 'no time zone when the lookups fail' do
    WhereTZ.stub(:lookup, ->(*) { raise ArgumentError, 'Point outside any known timezone' }) do
      assert_nil TimezoneLookup.zone_at(51.5, -0.12)
    end
    TZInfo::Country.stub(:get, ->(*) { raise TZInfo::InvalidCountryCode }) do
      assert_nil TimezoneLookup.country_zone('United Kingdom')
    end
    assert_nil TimezoneLookup.rails_name('Not/A_Zone')
    refute TimezoneLookup.same_offsets?('London', 'Not a zone')
  end
end
