require 'test_helper'

class TrackingTest < ActionDispatch::IntegrationTest
  test 'Does not automatically track visits' do
    assert_no_difference('Ahoy::Visit.count') do
      get '/'
    end
  end
end
