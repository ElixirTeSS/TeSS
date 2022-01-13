require 'test_helper'

class InvitationMailerTest < ActionMailer::TestCase

  setup do
    @user = users(:regular_user)
    @curator = users(:curator)
    @admin = users(:admin)
  end

  teardown do

  end

  test 'new invitation not allowed' do
    sign_in @user

    get '/users/invitation/new'

    follow_redirect!
    assert_equal "/", path
    

  end

end
