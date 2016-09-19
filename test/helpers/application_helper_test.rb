require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase

  setup do
    @old_material = materials(:bad_material)
    @old_material.last_scraped = Time.parse('1912-04-15')
    @old_material.scraper_record = true
    @new_material = materials(:good_material)
    @new_material.last_scraped = Time.now
    @new_material.scraper_record = true
  end


  test "icon should be correct for material scraped today" do
    expected_result  = "<span class='fresh-icon pull-right'>#{icon_for(:scraped_today, 'large')}</span>".html_safe
    assert_equal(scrape_status_icon(@new_material, 'large'),expected_result)
    assert_match /fresh-icon/, expected_result
    assert_match /fa-check-circle-o/, expected_result
  end

  test "icon should be correct for material not scraped for a while" do
    expected_result = "<span class='stale-icon pull-right'>#{icon_for(:not_scraped_recently, 'large')}</span>".html_safe
    expected_result.gsub!(/%SUB%/, (@old_material.last_scraped.to_s))
    assert_equal(scrape_status_icon(@old_material, 'large'),expected_result)
    assert_match /stale-icon/, expected_result
    assert_match /fa-exclamation-circle/, expected_result
  end

end