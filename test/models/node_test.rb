require 'test_helper'

class NodeTest < ActiveSupport::TestCase

  test "can load seed data" do
    hash = JSON.parse(File.read(File.join(Rails.root, 'test', 'fixtures', 'files', 'node_test_data.json')))
    assert_difference('Node.count', 3) do
      assert_difference('StaffMember.count', 6) do
        Node.load_from_hash(hash)
      end
    end
  end


end
