require 'test_helper'

class CommunityTest < ActiveSupport::TestCase
  test 'find community by id' do
    c = Community.find('uk')
    assert c
    assert_equal 'UK training', c.name
    assert_equal({ 'node' => 'United Kingdom' }, c.filters)
    assert_equal 'Some text about what the community is bla bla bla', c.description
    assert_equal "🇬🇧", c.flag
    assert_equal 'GB', c.country_code

    c = Community.find('be')
    assert c
    assert_equal 'Belgium Corner', c.name

    c = Community.find('cool')
    assert c
    assert_equal 'Cool Crew', c.name

    assert_nil Community.find('uck')
    assert_nil Community.find(nil)
  end

  test 'find community for country' do
    c = Community.for_country({ 'iso_code' => 'GB'})
    assert c
    assert_equal 'UK training', c.name

    c = Community.for_country({ 'iso_code' => 'BE'})
    assert c
    assert_equal 'Belgium Corner', c.name

    assert_nil Community.for_country({ 'iso_code' => 'DE'})
    assert_nil Community.for_country({ 'iso_code' => 'UK'})
    assert_nil Community.for_country({ 'iso_code' => 'england'})
    assert_nil Community.for_country({ 'iso_code' => nil})
    assert_nil Community.for_country({ 'bananas' => 32 })
    assert_nil Community.for_country(nil)
  end
end
