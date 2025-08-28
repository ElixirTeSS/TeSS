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
    assert_equal 'DE', narnia.country_code

    updated_hash = node_data_hash
    updated_hash['nodes'].first['country_code'] = 'ES'
    updated_nodes = []
    assert_no_difference('Node.count') do
      assert_no_difference('StaffMember.count') do
        updated_nodes = Node.load_from_hash(updated_hash)
      end
    end
    assert_equal node_ids, updated_nodes.map(&:id).sort
    assert_equal 'ES', narnia.reload.country_code
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
    assert_difference('countries_hash.keys.size', 251) do
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

  test 'can get resources through providers and directly associated' do
    node = nodes(:westeros)
    provider = content_providers(:provider_with_empty_image_url)
    provider.update!(node: node)

    e1 = events(:one)
    e1.update!(content_provider: provider)
    e2 = events(:two)
    node.events << e2
    node.reload

    assert_equal [e1], node.provider_events.to_a
    assert_equal [e2], node.events.to_a
    assert_equal [e1, e2], node.related_events.to_a.sort_by(&:title)

    m1 = materials(:interpro)
    m1.update!(content_provider: provider)
    m2 = materials(:prints)
    node.materials << m2
    node.reload

    assert_equal [m1], node.provider_materials.to_a
    assert_equal [m2], node.materials.to_a
    assert_equal [m1, m2], node.related_materials.to_a.sort_by(&:title)
  end

  test 'validates country code' do
    node = nodes(:good)
    assert node.valid?

    node.country_code = 'XZ'
    refute node.valid?
    assert node.errors.added?(:country_code, :inclusion, value: 'XZ')

    node.country_code = nil
    assert node.valid?
  end

  test 'full title' do
    assert_equal 'ELIXIR Sweden', Node.new(title: 'Sweden').full_title
    assert_equal 'ELIXIR UK', Node.new(title: 'United Kingdom').full_title
    assert_equal 'EMBL-EBI', Node.new(title: 'EMBL-EBI').full_title
    assert_equal 'ELIXIR Westeros', nodes(:westeros).full_title
  end

  private

  def node_data_hash
    JSON.parse(File.read(File.join(Rails.root, 'test', 'fixtures', 'files', 'node_test_data.json')))
  end

end
