# frozen_string_literal: true

require 'test_helper'

class ProfileTest < ActiveSupport::TestCase
  setup do
    WebMock.stub_request(:any, 'http://example.com').to_return(status: 200, body: 'hi')
  end

  test 'full name' do
    assert_equal 'Hannah Montana', Profile.new(firstname: 'Hannah', surname: 'Montana').full_name
    assert_equal 'Bob', Profile.new(firstname: 'Bob').full_name
  end

  test 'should strip name and email' do
    WebMock.stub_request(:any, 'http://website.com').to_return(status: 200, body: 'hi')
    profile = users(:regular_user).profile
    assert profile.update(firstname: ' Space ',
                          surname: "\tSpaceson\r\n",
                          website: ' http://website.com',
                          orcid: '  https://orcid.org/0000-0002-1825-0097 ')

    assert_equal 'Space', profile.firstname
    assert_equal 'Spaceson', profile.surname
    assert_equal 'http://website.com', profile.website
    assert_equal 'https://orcid.org/0000-0002-1825-0097', profile.orcid
  end

  test 'validates orcid' do
    profile = users(:regular_user).profile

    # check validation of invalid orcid
    refute profile.update(orcid: 'https://orcid.org/000-0002-1825-0097x')
    assert profile.errors.added?(:orcid, "isn't a valid ORCID identifier")

    # check validation of valid orcid - id only
    assert profile.update(orcid: '0000-0002-1825-0097')
    assert profile.update(orcid: '0000-0001-5109-3700')
    assert profile.update(orcid: '0000-0002-1694-233X')

    # check validation of valid orcid - bad check bit
    refute profile.update(orcid: '0000-0002-1825-0099')
    assert profile.errors.added?(:orcid, "isn't a valid ORCID identifier")

    # check validation of invalid orcid
    refute profile.update(orcid: 'https://orcid.org/0000-0001-1234-9999')
    assert profile.errors.added?(:orcid, "isn't a valid ORCID identifier")

    # check validation of valid orcid - fixes non-secure scheme
    assert profile.update(orcid: 'http://orcid.org/0000-0002-1825-0097')
    assert_equal 'https://orcid.org/0000-0002-1825-0097', profile.orcid

    # check validation of invalid orcid - scheme and host only
    refute profile.update(orcid: 'https://orcid.org/')
    assert_equal "ORCID isn't a valid ORCID identifier", profile.errors.full_messages_for(:orcid).first

    # check validation of invalid orcid, preserves original value
    refute profile.update(orcid: 'some junk')
    assert_equal "ORCID isn't a valid ORCID identifier", profile.errors.full_messages_for(:orcid).first
    assert_equal 'some junk', profile.orcid

    # check validation of blank orcid
    assert profile.update(orcid: '')
    assert profile.orcid.blank?
  end

  test 'validates website' do
    WebMock.stub_request(:any, 'https://bad-domain.example/').to_return(status: 500, body: 'bad')
    WebMock.stub_request(:any, 'http://200host.com').to_return(status: 200, body: 'hi')
    WebMock.stub_request(:any, 'http://404host.com').to_return(status: 404, body: 'hi')
    WebMock.stub_request(:any, 'http://slowhost.com').to_timeout

    profile = users(:regular_user).profile

    # accessible domain
    assert profile.update(website: 'http://200host.com')

    # blocked domain
    refute profile.update(website: 'https://bad-domain.example/')
    assert profile.errors.added?(:website, 'is blocked')
    refute profile.errors.added?(:website, 'is not accessible'), 'connection should not be attempted to blocked domains'

    # inaccessible domain
    refute profile.update(website: 'http://404host.com')
    assert profile.errors.added?(:website, 'is not accessible')
    refute profile.errors.added?(:website, 'is blocked')

    # private address
    refute profile.update(website: 'http://127.0.0.1')
    assert profile.errors.added?(:website, 'is not accessible')

    # address that times out
    refute profile.update(website: 'http://slowhost.com')
    assert profile.errors.added?(:website, 'is not accessible')
  end
end
