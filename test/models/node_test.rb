require 'test_helper'

class NodeTest < ActiveSupport::TestCase


=begin
  test "invalid home page" do
    sign_in users(:regular_user)
    node = nodes(:no_url)
    assert_not node.save!
  end

  test "no name" do
    sign_in users(:regular_user)
    node = nodes(:no_name)
    assert_not node.save!
  end

  test "correct save" do
    sign_in users(:regular_user)
    node = nodes(:good)
    assert_not node.save!
  end
=end

end
