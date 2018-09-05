require 'test_helper'

class NodeTest < ActiveSupport::TestCase

  test 'can create a node and staff' do
    node = Node.new(user: users(:admin), name: 'Kilburn', country_code: 'ES')
    node.staff.build(name: 'Tom', email: 'tk@example.com', role: 'Training coordinator')
    assert node.valid?
    assert node.save
    assert node.staff.any?
  end

  test 'cannot create a node with duplicate name' do
    Node.create(user: users(:admin), name: 'Kilburn', country_code: 'ES')
    node2 = Node.new(user: users(:admin), name: 'Kilburn', country_code: 'ES')
    refute node2.valid?
    refute node2.save
    assert node2.errors.any?
  end

  test 'can load seed data' do
    hash = node_data_hash
    assert_difference('Node.count', 3) do
      assert_difference('StaffMember.count', 6) do
        Node.load_from_hash(hash)
      end
    end
  end

  test 'can update seed data' do
    hash = node_data_hash
    nodes = Node.load_from_hash(hash)
    node_ids = nodes.map(&:id).sort
    narnia = nodes.first
    assert_equal 'NN', narnia.country_code

    updated_hash = node_data_hash
    updated_hash['nodes'].first['country_code'] = 'XY'
    updated_nodes = []
    assert_no_difference('Node.count') do
      assert_no_difference('StaffMember.count') do
        updated_nodes = Node.load_from_hash(updated_hash)
      end
    end
    assert_equal node_ids, updated_nodes.map(&:id).sort
    assert_equal 'XY', narnia.reload.country_code
  end

  test 'can update staff via seed data' do
    hash = node_data_hash
    Node.load_from_hash(hash)
    assert_equal 'Aslan', Node.find_by_name('Narnia').staff.first.name

    updated_hash = node_data_hash
    updated_hash['nodes'].first['staff'] = [{ 'name' => 'White Witch',
                                              'email' => 'ww@example.com',
                                              'role' => 'Training coordinator' }]
    assert_no_difference('StaffMember.count') do
      Node.load_from_hash(updated_hash)
    end

    assert_equal 'White Witch', Node.find_by_name('Narnia').staff.first.name
  end

  test 'can load countries data' do
    countries_hash = {}
    assert_difference('countries_hash.keys.size', 250) do
      countries_hash = JSON.parse(File.read(File.join(Rails.root, 'config', 'data', 'countries.json')))
    end
  end

  test 'can get staff and training coordinators' do
    node = nodes(:good)
    assert_equal 2, node.staff.length
    assert_equal 1, node.staff.training_coordinators.length
    assert_equal 'John Doe', node.staff.training_coordinators.first.name
    assert_equal ['John Doe', 'Joe Bloggs'].sort, node.staff.map(&:name).sort
  end

  test 'should have content providers' do
    node = nodes(:good)
    assert_equal 1, node.content_providers.length
    assert node.content_providers[0] == content_providers(:goblet)
  end

  private

  def node_data_hash
    JSON.parse(File.read(File.join(Rails.root, 'test', 'fixtures', 'files', 'node_test_data.json')))
  end

end
