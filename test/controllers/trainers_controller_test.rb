require 'test_helper'

class TrainersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user1 = users(:trainer_user)
    @user2 = users(:regular_user)
    @lucy = users(:banned_user)
    @admin = users(:admin)
  end

=begin
  test  'get all trainers' do
    get :index
    assert_response :success
    trainers = assigns(:trainers)
    assert_not_nil trainers
    trainers.each do | trainer |
      puts "trainer full_name[#{trainer.full_name}] public[#{trainer.public.to_s}]"
    end
    assert_equal 3, trainers.size
  end
=end

end
