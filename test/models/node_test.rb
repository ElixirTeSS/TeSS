require 'test_helper'

class NodeTest < ActiveSupport::TestCase

  test "invalid home page" do
    node = @nodes['no_url']
    assert_not node.save
  end

  test "no name" do
    node = @nodes['no_name']
    assert_not node.save
  end

  test "correct save" do
    node = @nodes['good']
    assert_not node.save
  end



end
