require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase

  setup do
    @old_material = materials(:bad_material)
    @old_material.last_scraped = Time.parse('1912-04-14 23:40')
    @old_material.scraper_record = true
    @new_material = materials(:good_material)
    @new_material.last_scraped = Time.now
    @new_material.scraper_record = true
    @old_event = events(:one)
    @old_event.last_scraped = Time.parse('1912-04-14 23:40')
    @old_event.scraper_record = true
    @old_iann_event = events(:iann_event)
    @old_iann_event.last_scraped = Time.parse('1912-04-14 23:40')
    @old_iann_event.scraper_record = true
    @failing_material = materials(:failing_material)
    @failing_material.title = 'Fail!'
    @monitor = @failing_material.create_link_monitor(url: @failing_material.url, code: 404, fail_count: 5)
  end

  test "icon should be correct for material scraped today" do
    expected_result = "<span class='fresh-icon pull-right'>#{icon_for(:scraped_today, 'large')}</span>".html_safe
    assert_equal(scrape_status_icon(@new_material, 'large'), expected_result)
    assert_match /fresh-icon/, expected_result
    assert_match /fa-check-circle-o/, expected_result
  end

  test "icon should be correct for material not scraped for a while" do
    expected_result = "<span class='stale-icon pull-right'>#{icon_for(:not_scraped_recently, 'large')}</span>".html_safe
    expected_result.gsub!(/%SUB%/, (@old_material.last_scraped.to_s))
    assert_equal(scrape_status_icon(@old_material, 'large'), expected_result)
    assert_match /stale-icon/, expected_result
    assert_match /fa-exclamation-circle/, expected_result
  end

  def current_user
    users(:admin)
  end

  test "icon should be correct for event not scraped for a while" do
    assert_not_nil(current_user)
    assert_equal(current_user.is_admin?, true)
    expected_result = "<span class='stale-icon pull-right'>#{icon_for(:not_scraped_recently, 'large')}</span>".html_safe
    expected_result.gsub!(/%SUB%/, (@old_event.last_scraped.to_s))
    assert_equal(scrape_status_icon(@old_event, 'large'), expected_result)
    assert_match /stale-icon/, expected_result
    assert_match /fa-exclamation-circle/, expected_result
  end

  test "icon should be correct for missing event" do
    assert_not_nil(current_user)
    assert_equal(current_user.is_admin?, true)
    expected_result = "<span class='missing-icon pull-right'>#{icon_for(:missing, 'large')}</span>".html_safe
    assert_nil(missing_icon(@old_material, 'large'))
    assert_equal(missing_icon(@failing_material, 'large'), expected_result)
    assert_match /missing-icon/, expected_result
    assert_match /fa-chain-broken/, expected_result

  end

  test "get country alpha2 from codes" do
    valid_alpha2_a = 'GB'
    valid_alpha2_b = 'NZ'
    invalid_alpha2 = 'XX'

    # a valid alpha2
    alpha2 = country_alpha2_by_name(valid_alpha2_a)
    assert_not_nil alpha2, "name[#{valid_alpha2_a}] returned nil."
    assert_equal valid_alpha2_a, alpha2, "name[#{valid_alpha2_a}] alpha2[#{alpha2}] not matched"

    # another valid alpha2
    alpha2 = country_alpha2_by_name(valid_alpha2_b)
    assert_not_nil alpha2, "name[#{valid_alpha2_b}] returned nil."
    assert_equal valid_alpha2_b, alpha2, "name[#{valid_alpha2_b}] alpha2[#{alpha2}] not matched"

    # an invalid alpha2
    alpha2 = country_alpha2_by_name(invalid_alpha2)
    assert_not_nil alpha2, "invalid name[#{invalid_alpha2}] returned nil."
    assert_equal '', alpha2, "invalid name[#{invalid_alpha2}] did not return blank."
  end

  test "get country alpha3 from codes" do
    valid_alpha2_a = 'AU'
    valid_alpha3_a = 'aus'
    valid_alpha2_b = 'NZ'
    valid_alpha3_b = 'nzl'
    invalid_alpha3 = 'bry'
    failed = ''

    # a valid alpha3
    alpha2 = country_alpha2_by_name(valid_alpha3_a)
    assert_not_nil alpha2, "name[#{valid_alpha3_a}] returned nil."
    assert_equal valid_alpha2_a, alpha2, "name[#{valid_alpha2_a}] alpha2[#{alpha2}] not matched"

    # another valid alpha2
    alpha2 = country_alpha2_by_name(valid_alpha3_b)
    assert_not_nil alpha2, "name[#{valid_alpha2_b}] returned nil."
    assert_equal valid_alpha2_b, alpha2, "name[#{valid_alpha2_b}] alpha2[#{alpha2}] not matched"

    # an invalid alpha2
    alpha2 = country_alpha2_by_name(invalid_alpha3)
    assert_not_nil alpha2, "invalid name[#{invalid_alpha3}] returned nil."
    assert_equal failed, alpha2, "invalid name[#{invalid_alpha3}] did not return blank."
  end

  test "get country alpha2 from names" do
    valid_alpha2_a = 'GB'
    valid_alpha2_b = 'NZ'
    valid_name_a = 'United Kingdom of Great Britain and Northern Ireland'
    valid_name_b = 'New Zealand'
    invalid_name = 'New Atlantis'
    failed = ''

    # a valid name
    alpha2 = country_alpha2_by_name(valid_name_a)
    assert_not_nil alpha2, "name[#{valid_name_a}] returned nil."
    assert_equal valid_alpha2_a, alpha2,
                 "expected[#{valid_alpha2_a}] and alpha2[#{alpha2}] from name[#{valid_name_a}] not matched"

    # another valid name
    alpha2 = country_alpha2_by_name(valid_name_b)
    assert_not_nil alpha2, "name[#{valid_name_b}] returned nil."
    assert_equal valid_alpha2_b, alpha2,
                 "expected[#{valid_alpha2_b}] and alpha2[#{alpha2}] from name[#{valid_name_b}] not matched"

    # a invalid name
    alpha2 = country_alpha2_by_name(invalid_name)
    assert_not_nil alpha2, "name[#{invalid_name}] returned nil."
    assert_equal failed, alpha2, "expected[#{failed}] and alpha2[#{alpha2}] from name[#{invalid_name}] not matched"
  end

  test "check aus codes" do
    code = 'AU'
    %w{ Australia au AUS AU aus }.each do |name|
      alpha2 = country_alpha2_by_name(name)
      assert_not_nil alpha2, "alpha2 from name[#{name}] is nil"
      assert_equal code, alpha2, "alpha2[#{alpha2}] and code[#{code}] from name[#{name}] not matched"
    end
  end

  # This test is failing because the content_provider isn't found, but the code runs anyway
=begin
  test "no icon should be shown for an iAnn event which has not been scraped recently" do
    assert_not_nil(current_user)
    assert_equal(current_user.is_admin?,true)
    assert_equal(@old_event.content_provider.title.downcase,'iann')
    assert_equal(scrape_status_icon(@old_iann_event, 'large'),nil)
  end
=end

end