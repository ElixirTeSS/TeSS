require 'test_helper'

class ProfileTest < ActiveSupport::TestCase

  test 'full name' do
    assert_equal 'Hannah Montana', Profile.new(firstname: 'Hannah', surname: 'Montana').full_name
    assert_equal 'Bob', Profile.new(firstname: 'Bob').full_name
  end

end
