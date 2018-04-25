require 'test_helper'

class ExternalResourceTest < ActiveSupport::TestCase

  test 'correctly identifiers a bio.tools external resource' do
    assert external_resources(:biotools).is_tool?
    refute external_resources(:biotools).is_fairsharing?
    refute external_resources(:biotools).is_generic_external_resource?

    assert external_resources(:biotwools).is_tool?
    refute external_resources(:biotwools).is_fairsharing?
    refute external_resources(:biotwools).is_generic_external_resource?
  end

  test 'correctly identifiers a resource is not from bio.tools' do
    refute external_resources(:google).is_tool?
    refute external_resources(:google).is_fairsharing?
    assert external_resources(:google).is_generic_external_resource?

    refute external_resources(:tess).is_tool?
    refute external_resources(:tess).is_fairsharing?
    assert external_resources(:tess).is_generic_external_resource?
  end

  test 'get API url of resource' do
    api_url = external_resources(:biotwools).api_url_of_tool
    assert_equal 'https://bio.tools/api/tool/FuNeL', api_url

    assert_nil external_resources(:google).api_url_of_tool
  end

  test 'get fairsharing API url' do
    database = ExternalResource.new(url: 'https://fairsharing.org/biodbcore-123456')
    assert_equal 'https://fairsharing.org/api/database/summary/biodbcore-123456', database.api_url_of_fairsharing
    refute database.is_tool?
    assert database.is_fairsharing?
    refute database.is_generic_external_resource?

    standard = ExternalResource.new(url: 'https://fairsharing.org/bsg-s123456')
    assert_equal 'https://fairsharing.org/api/standard/summary/bsg-s123456', standard.api_url_of_fairsharing
    refute standard.is_tool?
    assert standard.is_fairsharing?
    refute standard.is_generic_external_resource?

    policy = ExternalResource.new(url: 'https://fairsharing.org/bsg-p123456')
    assert_equal 'https://fairsharing.org/api/policy/summary/bsg-p123456', policy.api_url_of_fairsharing
    refute policy.is_tool?
    assert policy.is_fairsharing?
    refute policy.is_generic_external_resource?
  end

end
