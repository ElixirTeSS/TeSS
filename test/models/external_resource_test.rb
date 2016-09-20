require 'test_helper'

class ExternalResourceTest < ActiveSupport::TestCase

  test 'correctly identifiers a bio.tools external resource' do
    assert_equal external_resources(:biotools).is_tool?, true
    assert_equal external_resources(:biotwools).is_tool?, true
  end

  test 'correctly identifiers a resource is not from bio.tools' do
    puts external_resources(:google).inspect
    puts external_resources(:google).is_tool?
    assert_equal external_resources(:google).is_tool?, false
    assert_equal external_resources(:tess).is_tool?, false
  end

  test 'get API url of resource' do
    api_url = external_resources(:biotwools).api_url_of_tool
    assert_not_empty api_url
    assert_equal 'https://dev.bio.tools/api/tool/FuNeL', api_url
    assert_empty external_resources(:google).api_url_of_tool
  end

end
