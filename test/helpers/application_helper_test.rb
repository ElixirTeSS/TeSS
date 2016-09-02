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

  test "outdated image supplied for old material" do
    result = conditional_icon_for(:not_scraped_recently,@old_material)
    assert_not_equal(conditional_icon_for(:not_scraped_recently,@old_material),nil)
  end

  test "no outdated image supplied for new material" do
    assert_equal(conditional_icon_for(:not_scraped_recently,@new_material),nil)
  end

end