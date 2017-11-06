require 'test_helper'

class MaterialTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end


  setup do
    @user = User.new(:username=>'bobo',
                  :email=>'exampl@example.com',
                  :role => Role.first,
                  :password => SecureRandom.base64
    )
    @user.save!
    @material = Material.new(:title => 'title',
                             :short_description => 'short desc',
                             :url => 'http://goog.e.com',
                             :user => @user,
                             :authors => ['horace', 'flo'],
                             :content_provider => ContentProvider.first)
    @material.save!
  end

  test 'should reassign owner when user deleted' do
    material_id = @material.id
    owner = @material.user
    assert_not_equal 'default_user', owner.role.name
    owner.destroy
    #Reload the material
    material = Material.find_by_id(material_id)
    assert_equal 'default_user', material.user.role.name
  end

  test 'should convert string value to empty array in authors' do
    assert_not_equal @material.authors, []
    assert @material.update_attributes(authors: 'string')
    assert_equal [], @material.authors
  end

  test 'should convert nil to empty array in authors fields' do
    assert_not_equal @material.authors, []
    assert @material.update_attributes(authors: nil)
    assert_equal [], @material.authors
  end

  test 'should strip bad values from authors array input' do
    authors = ['john', 'bob', nil, [], '', 'frank']
    expected_authors = ['john', 'bob', 'frank']
    assert @material.update_attributes(authors: authors)
    assert_equal expected_authors, @material.authors
  end

  test 'should delete material when content provider deleted' do
    material = @material
    content_provider = @material.content_provider
    assert Material.find_by_id(material.id)
    assert content_provider.destroy
    assert_nil Material.find_by_id(material.id)
  end

  test 'can get associated nodes for material' do
    m = materials(:good_material)

    assert_equal [], m.nodes
    assert_equal 1, m.associated_nodes.count
    assert_includes m.associated_nodes, nodes(:good)
  end

  test 'can add a node to a material' do
    m = materials(:good_material)

    assert_difference('NodeLink.count', 1) do
      m.nodes << nodes(:westeros)
    end

    assert_equal 1, m.nodes.count
    assert_includes m.nodes, nodes(:westeros)
    assert_equal 2, m.associated_nodes.count
    assert_includes m.associated_nodes, nodes(:good)
    assert_includes m.associated_nodes, nodes(:westeros)
  end

  test 'validates material CV fields' do
    m = materials(:good_material)

    m.difficulty_level = 'ez pz'
    m.licence = '__DEfinitely Not a VAlId LiCEnCe__'

    refute m.save
    assert_equal 2, m.errors.count
    assert_equal ["must be a controlled vocabulary term"], m.errors[:difficulty_level]
    assert_equal ["must be a controlled vocabulary term"], m.errors[:licence]

    m.difficulty_level = 'beginner'
    m.licence = 'GPL-3.0'
    assert m.save
    assert_equal 0, m.errors.count
  end

  test 'node names/associated node names includes names of nodes' do
    m = materials(:good_material)

    assert_includes m.associated_node_names, nodes(:good).name
    assert_not_includes m.node_names, nodes(:good).name

    m.nodes << nodes(:westeros)

    assert_includes m.associated_node_names, nodes(:good).name
    assert_includes m.associated_node_names, nodes(:westeros).name

    assert_not_includes m.node_names, nodes(:good).name
    assert_includes m.node_names, nodes(:westeros).name
  end

  test 'can set licence either using key or URL' do
    m = materials(:good_material)

    m.licence = 'CC-BY-4.0'
    assert m.valid?
    assert_equal 'CC-BY-4.0', m.licence

    m.licence = 'https://creativecommons.org/licenses/by-sa/4.0/'
    assert m.valid?
    assert_equal 'CC-BY-SA-4.0', m.licence

    m.licence = 'https://not.a.real.licence.golf'
    refute m.valid?
    assert_equal 'https://not.a.real.licence.golf', m.licence, "should preserve URL user input if it didn't match any licenses in the dictionary"
  end

  test 'can check if matearial is stale (has not been scraped recently)' do
    m = materials(:good_material)

    m.last_scraped = nil
    refute m.stale?

    m.last_scraped = Time.now
    refute m.stale?

    m.last_scraped = (Scrapable::THRESHOLD + 1.hour).ago
    assert m.stale?
  end

  test 'can associate event with material' do
    event = events(:one)
    material = materials(:good_material)

    assert_difference('EventMaterial.count', 1) do
      material.events << event
    end
  end

  test 'can delete an material with associated events' do
    event = events(:one)
    material = materials(:good_material)
    material.events << event

    assert_difference('EventMaterial.count', -1) do
      assert_difference('Material.count', -1) do
        assert_no_difference('Event.count') do
          material.destroy
        end
      end
    end
  end
end
