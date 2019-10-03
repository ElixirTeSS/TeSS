require 'test_helper'

class MaterialTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end


  setup do
    @user = users(:regular_user)
    @material = Material.create!(title: 'title',
                                 short_description: 'short desc',
                                 url: 'http://goog.e.com',
                                 user: @user,
                                 authors: ['horace', 'flo'],
                                 content_provider: content_providers(:goblet))
  end

  test 'should reassign owner when user deleted' do
    owner = @material.user
    assert_not_equal 'default_user', owner.role.name
    owner.destroy
    #Reload the material
    material = @material.reload
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

  test 'can still retrieve deprecated topics' do
    material = materials(:good_material)
    material.scientific_topic_uris = ['http://edamontology.org/topic_0213'] # Deprecated "Mice or rats" topic
    material.save!

    assert_includes material.reload.scientific_topic_names, 'Mice or rats'
    topic = material.scientific_topics.last
    assert_equal 'Mice or rats', topic.label
    assert topic.deprecated?
  end

  test 'user_requires_approval?' do
    user = users(:unverified_user)

    first_material = user.materials.build(title: 'bla', url: 'http://example.com/spam', short_description: '123')
    assert first_material.user_requires_approval?
    assert first_material.from_unverified_or_rejected?
    first_material.save!

    second_material = user.materials.build(title: 'bla', url: 'http://example.com/spam2', short_description: '123')
    refute second_material.user_requires_approval?
  end

  test 'from_unverified_or_rejected?' do
    user = users(:unverified_user)

    first_material = user.materials.create!(title: 'bla', url: 'http://example.com/spam', short_description: '123')
    assert first_material.from_unverified_or_rejected?

    user.role = Role.rejected
    user.save!

    second_material = user.materials.create(title: 'bla', url: 'http://example.com/spam2', short_description: '123')
    assert second_material.from_unverified_or_rejected?

    user.role = Role.approved
    user.save!

    third_material = user.materials.create(title: 'bla', url: 'http://example.com/spam3', short_description: '123')
    refute third_material.from_unverified_or_rejected?
  end

  test 'should not add duplicate external resources' do
    material = materials(:material_with_external_resource)
    resources = material.external_resources

    assert_no_difference('ExternalResource.count') do
      material.external_resources_attributes = [{ title: 'TeSS', url: 'https://tess.elixir-uk.org/' }]
      material.save!
    end

    assert_equal resources, material.reload.external_resources
  end

  test 'should not remove duplicate external resource URLs if they have different titles' do
    material = materials(:material_with_external_resource)

    assert_difference('ExternalResource.count', 1) do
      material.external_resources_attributes = [{ title: 'Cool Website!', url: 'https://tess.elixir-uk.org/' }]
      material.save!
    end
  end

  test 'should not remove duplicate external resource titles if they have different titles' do
    material = materials(:material_with_external_resource)

    assert_difference('ExternalResource.count', 1) do
      material.external_resources_attributes = [{ title: 'TeSS', url: 'https://tess.oerc.ox.ac.uk/' }]
      material.save!
    end
  end

  test 'should remove existing duplicate external resources on save' do
    material = materials(:material_with_external_resource)
    res_count = material.external_resources.count
    new_resource = material.external_resources.create!({ title: 'TeSS', url: 'https://tess.elixir-uk.org/' })
    assert_equal res_count + 1, material.reload.external_resources.count
    assert_equal 2, material.external_resources.where(title: 'TeSS').count

    assert_difference('ExternalResource.count', -1) do
      material.save!
    end

    assert_equal res_count, material.reload.external_resources.count
    assert_equal 1, material.external_resources.where(title: 'TeSS').count
    assert_not_includes material.external_resources, new_resource, 'Should preserve oldest external resource'
  end

  test 'verified users scope' do
    bad_user = users(:unverified_user)
    bad_material = bad_user.materials.build(title: 'bla', url: 'http://example.com/spam', short_description: 'vvv')
    assert bad_material.user_requires_approval?
    bad_material.save!

    good_user = users(:regular_user)
    good_material = good_user.materials.build(title: 'h', url: 'http://example.com/good-stuff', short_description: 'vvv')
    refute good_material.user_requires_approval?
    good_material.save!

    # Unscoped
    assert_includes Material.where(short_description: 'vvv').to_a, good_material
    assert_includes Material.where(short_description: 'vvv').to_a, bad_material
    # Scoped
    assert_includes Material.from_verified_users.where(short_description: 'vvv').to_a, good_material
    refute_includes Material.from_verified_users.where(short_description: 'vvv').to_a, bad_material
  end

  test 'creates sensible friendly ID' do
    # Reserved word throws error
    reserved_word_material = Material.new(title: 'edit',
                                          short_description: 'short desc',
                                          url: 'http://tess.elixir-europe.org',
                                          user: @user)
    refute reserved_word_material.save

    # Numeric slug generates UUID slug
    material = Material.create!(title: '123',
                                short_description: 'short desc',
                                url: 'http://tess.elixir-europe.org',
                                user: @user)
    refute_match(/\A\d+\Z/, material.friendly_id)

    material = Material.create!(title: '第9回研究会開催案内',
                                short_description: 'short desc',
                                url: 'http://tess.elixir-europe.org',
                                user: @user)
    refute_match(/\A\d+\Z/, material.friendly_id)
  end
end
