require 'test_helper'

class ProfileTest < ActiveSupport::TestCase
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
end
