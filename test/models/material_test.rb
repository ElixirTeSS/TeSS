require 'test_helper'

class MaterialTest < ActiveSupport::TestCase

  setup do
    @user = users :regular_user
    @event = events :kilburn
    @material = Material.create!(title: 'title',
                                 description: 'short desc',
                                 url: 'http://goog.e.com',
                                 user: @user,
                                 authors: ['horace', 'flo'],
                                 doi: 'https://doi.org/10.1011/RSE.2019.55',
                                 licence: 'CC-BY-NC-SA-4.0',
                                 keywords: ['goblet'],
                                 contact: 'default contact',
                                 content_provider: content_providers(:goblet),
                                 status: 'active'
    )
    assert_not_nil @user
    assert_not_nil @event
    assert_not_nil @material
  end

  test 'should update optionals' do
    m = materials(:material_with_optionals)

    # check original values
    assert_not_nil m.content_provider, 'old content provider is nil.'
    assert_equal 'Goblet', m.content_provider.title, 'old content provider not matched.'

    assert_not_nil m.events, 'old events is nil.'
    assert_equal 2, m.events.size, 'old events size not matched.'
    assert_equal @event, m.events.find { |e| e.title == @event.title }, 'old events{:two} not matched.'

    assert_not_nil m.target_audience, 'old target audience is nil.'
    assert_equal 2, m.target_audience.size, 'old target audience size not matched.'
    assert_equal 'ECR', m.target_audience[1], 'old target audience[1] not matched.'

    assert_not_nil m.resource_type, 'old resource type is nil.'
    assert_equal 2, m.resource_type.size, 'old resource type size not matched.'
    assert_equal 'Quiz', m.resource_type[0], 'old resource type[0] not matched.'

    assert_equal 'Podcast', m.other_types, 'old other_types not matched.'
    assert_equal '1.0.3', m.version, 'old version not matched.'
    assert_equal 'development', m.status, 'old status not matched.'
    assert_equal '2021-07-12', m.date_created.to_fs('%Y-%m-%d'), 'old date created not matched.'
    assert_equal '2021-07-13', m.date_modified.to_fs('%Y-%m-%d'), 'old date modified not matched.'
    assert_equal '2021-07-14', m.date_published.to_fs('%Y-%m-%d'), 'old date published not matched.'

    assert_not_nil m.subsets, 'old subsets is nil.'
    assert_equal 2, m.subsets.size, 'old subsets size not matched.'
    assert_equal "#{m.url}/part-two", m.subsets[1], 'old subsets[1] not matched.'

    assert_not_nil m.authors, 'old authors is nil.'
    assert_equal 2, m.authors.size, 'old authors size not matched.'
    assert_equal 'Thomas Edison', m.authors[1], 'old authors[1] not matched.'

    assert_not_nil m.contributors, 'old contributors is nil.'
    assert_equal 1, m.contributors.size, 'old contributors size not matched.'
    assert_equal 'Dr Dre', m.contributors[0], 'old contributors[0] not matched.'

    assert_equal 'None', m.prerequisites, 'old prerequisites not matched.'
    assert_equal '1. Overview\  2. The main part\  3. Summing up', m.syllabus, 'old syllabus not matched.'
    assert_equal 'Understand the new materials model', m.learning_objectives, 'old learning objectives not matched.'

    # update optionals
    m.content_provider = content_providers(:iann)
    m.events = [events(:two)]
    m.target_audience = ['researcher']
    m.resource_type = ['infographic']
    m.other_types = 'Podcast, White Paper'
    m.version = '1.0.4'
    m.status = 'active'
    m.date_created = '2021-06-12'
    m.date_modified = '2021-06-13'
    m.date_published = '2021-06-14'
    m.subsets = []
    m.authors = ['Nikolai Tesla']
    m.contributors = ['Prof. Stephen Hawking']
    m.prerequisites = 'Bring your enthusiasm'
    m.syllabus = "1. Overview\  2. The main part\  3. Summary"
    m.learning_objectives = "- Understand the new materials model\  - Apply the new material model"

    # check update
    assert m.valid?
    assert m.save
    assert_equal 0, m.errors.count

    # get updated
    m2 = Material.find(m.id)
    assert_not_nil m2, 'updated material not found.'

    # check updated values
    assert_not_nil m2.content_provider, 'new content provider is nil.'
    assert_equal 'iAnn', m2.content_provider.title, 'new content provider not matched.'

    assert_not_nil m2.events, 'new events is nil.'
    assert_equal 1, m2.events.size, 'new events size not matched.'
    assert_equal events(:two), m2.events[0], 'new events[0] not matched.'

    assert_not_nil m2.target_audience, 'new target audience is nil.'
    assert_equal 1, m2.target_audience.size, 'new target audience size not matched.'
    assert_equal 'researcher', m2.target_audience[0], 'new target audience[0] not matched.'

    assert_not_nil m2.resource_type, 'new resource type is nil.'
    assert_equal 1, m2.resource_type.size, 'new resource type size not matched.'
    assert_equal 'infographic', m2.resource_type[0], 'new resource type[0] not matched.'

    assert_equal 'Podcast, White Paper', m2.other_types, 'new other_types not matched.'
    assert_equal '1.0.4', m2.version, 'new version not matched.'
    assert_equal 'active', m2.status, 'new status not matched.'
    assert_equal '2021-06-12', m2.date_created.to_fs('%Y-%m-%d'), 'new date created not matched.'
    assert_equal '2021-06-13', m2.date_modified.to_fs('%Y-%m-%d'), 'new date modified not matched.'
    assert_equal '2021-06-14', m2.date_published.to_fs('%Y-%m-%d'), 'new date published not matched.'

    assert_not_nil m2.subsets, 'new subsets is nil.'
    assert_equal 0, m2.subsets.size, 'new subsets size not matched.'

    assert_not_nil m2.authors, 'new authors is nil.'
    assert_equal 1, m2.authors.size, 'new authors size not matched.'
    assert_equal 'Nikolai Tesla', m2.authors[0], 'new authors[0] not matched.'

    assert_not_nil m2.contributors, 'new contributors is nil.'
    assert_equal 1, m2.contributors.size, 'new contributors size not matched.'
    assert_equal 'Prof. Stephen Hawking', m2.contributors[0], 'new contributors[0] not matched.'

    assert_equal 'Bring your enthusiasm', m2.prerequisites, 'new prerequisites not matched.'
    assert_equal "1. Overview\  2. The main part\  3. Summary", m2.syllabus, 'new syllabus not matched.'
    assert_equal "- Understand the new materials model\  - Apply the new material model", m2.learning_objectives,
                 'new learning objectives not matched.'
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
    assert @material.update(authors: 'string')
    assert_equal [], @material.authors
  end

  test 'should convert nil to empty array in authors fields' do
    assert_not_equal @material.authors, []
    assert @material.update(authors: nil)
    assert_equal [], @material.authors
  end

  test 'should remove bad values and strip authors array input' do
    authors = ['john', 'bob', nil, [], '', 'frank ']
    expected_authors = ['john', 'bob', 'frank']
    assert @material.update(authors: authors)
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

    # no longer valid - m.difficulty_level = 'ez pz'
    m.licence = '__DEfinitely Not a VAlId LiCEnCe__'

    refute m.save
    assert_equal 1, m.errors.count
    # no longer valid - assert_equal ["must be a controlled vocabulary term"], m.errors[:difficulty_level]
    assert_equal ["must be a controlled vocabulary term"], m.errors[:licence]

    # no longer valid - m.difficulty_level = 'beginner'
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

  test 'can set licence either using key, URL or SPDX URL in any case' do
    m = materials(:good_material)

    m.licence = 'CC-BY-4.0'
    assert m.valid?
    assert_equal 'CC-BY-4.0', m.licence

    m.licence = 'https://creativecommons.org/licenses/by-sa/4.0/'
    assert m.valid?
    assert_equal 'CC-BY-SA-4.0', m.licence

    m.licence = 'https://spdx.org/licenses/BSD-4-Clause-Shortened.html'
    assert m.valid?
    assert_equal 'BSD-4-Clause-Shortened', m.licence

    m.licence = 'https://spdx.org/licenses/MIT.json'
    assert m.valid?
    assert_equal 'MIT', m.licence

    m.licence = 'https://not.a.real.licence.golf'
    refute m.valid?
    assert_equal 'https://not.a.real.licence.golf', m.licence, "should preserve URL user input if it didn't match any licenses in the dictionary"

    m.licence = 'cc-by-4.0'
    assert m.valid?
    assert_equal 'CC-BY-4.0', m.licence

    m.licence = 'MPL-2.0-NO-COPYLEFT-EXCEPTION'
    assert m.valid?
    assert_equal 'MPL-2.0-no-copyleft-exception', m.licence

    m.licence = 'abcXYZ123'
    refute m.valid?
    assert_equal 'abcXYZ123', m.licence, "should preserve user input if it didn't match any licenses in the dictionary"
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

    first_material = user.materials.build(title: 'bla', url: 'http://example.com/spam', description: '123',
                                          doi: 'https://doi.org/10.1111/123.1235', licence: 'Fair', keywords: ['uno'],
                                          contact: 'default contact', status: 'active')
    assert first_material.user_requires_approval?
    assert first_material.from_unverified_or_rejected?
    first_material.save!

    second_material = user.materials.build(title: 'bla', url: 'http://example.com/spam2', description: '123',
                                           doi: 'https://doi.org/10.1111/123.1235', licence: 'Fair', keywords: ['dos'],
                                           contact: 'default contact', status: 'active')
    refute second_material.user_requires_approval?
  end

  test 'from_unverified_or_rejected?' do
    user = users(:unverified_user)

    first_material = user.materials.create!(title: 'bla', url: 'http://example.com/spam', description: '123',
                                            doi: 'https://doi.org/10.1111/123.1235', licence: 'Fair', keywords: ['uno'],
                                            contact: 'default contact', status: 'active')
    assert first_material.from_unverified_or_rejected?

    user.role = Role.rejected
    user.save!

    second_material = user.materials.create(title: 'bla', url: 'http://example.com/spam2', description: '123',
                                            doi: 'https://doi.org/10.1111/123.1235', licence: 'Fair', keywords: ['dos'],
                                            contact: 'default contact', status: 'development')
    assert second_material.from_unverified_or_rejected?

    user.role = Role.approved
    user.save!

    third_material = user.materials.create(title: 'bla', url: 'http://example.com/spam3', description: '123',
                                           doi: 'https://doi.org/10.1111/123.1235', licence: 'Fair', keywords: ['tres'],
                                           contact: 'default contact', status: 'archived')
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

  test 'should set external resources from params' do
    material = materials(:good_material)
    assert_empty material.external_resources

    assert_difference('ExternalResource.count', 2) do
      material.update!(external_resources: [{ title: 'Cool Website!', url: 'https://tess.elixir-uk.org/' },
                                            { title: 'Cooler Website!', url: 'https://tess.elixir-europe.org/' }])
    end

    er = material.reload.external_resources
    assert_equal 2, er.count
    assert_equal 'Cool Website!', er[0].title
    assert_equal 'https://tess.elixir-uk.org/', er[0].url
    assert_equal 'Cooler Website!', er[1].title
    assert_equal 'https://tess.elixir-europe.org/', er[1].url
  end

  test 'should remove redundant external resources and preserve IDs of retained ones' do
    material = materials(:material_with_external_resource)
    original_resources = material.external_resources.to_a
    assert_equal 3, original_resources.length

    # [
    #   { url: "https://tess.elixir-uk.org/", title: "TeSS" },
    #   { url: "https://bio.tools/tool/SR-Tesseler", title: "SR-Tesseler" },
    #   { url: "https://fairsharing.org/bsg-p123456", title: "Share Fairing" }
    # ]

    assert_difference('ExternalResource.count', -1) do
      material.update!(external_resources: [{ title: 'TeSS', url: 'https://tess.elixir-uk.org/' },
                                            { title: 'Changed title', url: 'https://bio.tools/tool/SR-Tesseler' }])
    end

    er = material.reload.external_resources
    assert_equal 2, er.count
    assert_equal 'TeSS', er[0].title
    assert_equal 'https://tess.elixir-uk.org/', er[0].url
    assert_equal original_resources[0].id, er[0].id, 'Should have preserved original ExternalResource'
    assert_equal 'Changed title', er[1].title
    assert_equal 'https://bio.tools/tool/SR-Tesseler', er[1].url
    assert_not_equal original_resources[1].id, er[1].id, 'Should have replaced modified ExternalResource'
  end

  test 'can set external resources using objects or params' do
    material = materials(:material_with_external_resource)
    original_resources = material.external_resources.to_a
    assert_equal 3, original_resources.length

    assert_no_difference('ExternalResource.count') do
      material.update!(external_resources: original_resources.first(2) +
        [{ title: 'Zombocom', url: 'https://zombo.com' }])
    end

    er = material.reload.external_resources
    assert_equal 3, er.count
    assert_equal 'TeSS', er[0].title
    assert_equal 'https://tess.elixir-uk.org/', er[0].url
    assert_equal original_resources[0].id, er[0].id, 'Should have preserved first ExternalResource'
    assert_equal 'SR-Tesseler', er[1].title
    assert_equal 'https://bio.tools/tool/SR-Tesseler', er[1].url
    assert_equal original_resources[1].id, er[1].id, 'Should have preserved second ExternalResource'
    assert_equal 'Zombocom', er[2].title
    assert_equal 'https://zombo.com', er[2].url
    assert_not_equal original_resources[2].id, er[2].id, 'Should have replaced third ExternalResource'
  end

  test 'verified users scope' do
    bad_user = users(:unverified_user)
    bad_material = bad_user.materials.build(title: 'bla', url: 'http://example.com/spam', description: 'vvv',
                                            doi: 'https://doi.org/10.1111/123.1235', contact: 'default contact',
                                            licence: 'Fair', keywords: %w{ key words }, status: 'active')
    assert bad_material.user_requires_approval?
    bad_material.save!

    good_user = users(:regular_user)
    good_material = good_user.materials.build(title: 'h', url: 'http://example.com/good-stuff',
                                              description: 'vvv', contact: 'default contact',
                                              doi: 'https://doi.org/10.1111/123.1235', status: 'active',
                                              licence: 'Fair', keywords: %w{ key words })
    refute good_material.user_requires_approval?
    good_material.save!

    # Unscoped
    assert_includes Material.where(description: 'vvv').to_a, good_material
    assert_includes Material.where(description: 'vvv').to_a, bad_material
    # Scoped
    assert_includes Material.from_verified_users.where(description: 'vvv').to_a, good_material
    refute_includes Material.from_verified_users.where(description: 'vvv').to_a, bad_material
  end

  test 'creates sensible friendly ID' do
    # Reserved word throws error
    reserved_word_material = Material.new(title: 'edit',
                                          description: 'long desc',
                                          url: 'http://tess.elixir-europe.org',
                                          doi: 'https://doi.org/10.1111/123.1235',
                                          licence: 'Fair',
                                          keywords: ['uno'],
                                          contact: 'default contact',
                                          user: @user,
                                          status: 'active')
    refute reserved_word_material.save

    # Numeric slug generates UUID slug
    material = Material.create!(title: '123',
                                description: 'short desc',
                                url: 'http://tess.elixir-europe.org',
                                doi: 'https://doi.org/10.1111/123.1235',
                                licence: 'Fair',
                                keywords: ['uno'],
                                contact: 'default contact',
                                user: @user,
                                status: 'development')
    refute_match(/\A\d+\Z/, material.friendly_id)

    material = Material.create!(title: '第9回研究会開催案内',
                                description: 'short desc',
                                url: 'http://tess.elixir-europe.org',
                                doi: 'https://doi.org/10.1111/123.1235',
                                licence: 'Fair',
                                keywords: ['uno'],
                                contact: 'default contact',
                                user: @user,
                                status: 'archived')
    refute_match(/\A\d+\Z/, material.friendly_id)
  end


  test 'validates URL format' do
    material = Material.new(title: 'Test', description: 'desc', user: users(:regular_user))

    refute material.valid?
    assert material.errors.added?(:url, :blank)

    material.url = '123'
    refute material.valid?
    assert material.errors.added?(:url, :url, value: '123')

    material.url = '/relative'
    refute material.valid?
    assert material.errors.added?(:url, :url, value: '/relative')

    material.url = 'git://something.git'
    refute material.valid?
    assert material.errors.added?(:url, :url, value: 'git://something.git')

    material.url = 'http://http-website.com/mat'
    assert material.valid?
    refute material.errors.added?(:url, :url, value: 'http://http-website.com/mat')

    material.url = 'https://https-website.com/mat'
    assert material.valid?
    refute material.errors.added?(:url, :url, value: 'https://https-website.com/mat')

    material.url = 'ftp://something/something'
    refute material.valid?
    assert material.errors.added?(:url, :url, value: 'ftp://something/something')
  end

  test 'duplicate' do
    user = users(:regular_user)
    node = nodes(:westeros)
    event = events(:one)
    material = Material.new(
      title: 'A material',
      description: 'Very helpful',
      user: user,
      url: 'https://materials.com/1',
      keywords: ['cool', 'great'],
      nodes: [node],
      external_resources_attributes: { '0' => { title: 'test', url: 'https://external-resource.com' } },
      events: [event],
      scientific_topic_names: ['Proteins', 'DNA'],
      operation_names: ['Variant calling']
    )

    assert material.save
    dup = nil
    assert material.slug

    # Duplicating should not create any records
    assert_no_difference('Material.count') do
      assert_no_difference('OntologyTermLink.count') do
        assert_no_difference('NodeLink.count') do
          assert_no_difference('ExternalResource.count') do
            assert_no_difference('EventMaterial.count') do
              dup = material.duplicate

              assert_equal 'A material', dup.title
              assert_equal 'Very helpful', dup.description
              assert_equal ['cool', 'great'], dup.keywords
              assert_nil dup.id
              assert_nil dup.slug
              assert_nil dup.url
              assert_equal [event], dup.events
              assert_equal [node], dup.nodes
              assert_equal ['Proteins', 'DNA'], dup.scientific_topic_names
              assert_equal ['Variant calling'], dup.operation_names
              assert_equal 1, dup.external_resources.length
              assert_equal 'test', dup.external_resources.first.title
              assert_equal 'https://external-resource.com', dup.external_resources.first.url
            end
          end
        end
      end
    end

    # Records are created when duplicate is saved
    assert_difference('Material.count', 1) do
      assert_difference('OntologyTermLink.count', 3) do
        assert_difference('NodeLink.count', 1) do
          assert_difference('ExternalResource.count', 1) do
            assert_difference('EventMaterial.count', 1) do
              dup.url = 'https://materials.com/2'
              assert dup.save
            end
          end
        end
      end
    end
  end

  test 'should strip attributes' do
    assert @material.update(title: ' Material  Title  ', url: " https://material.com\n")
    assert_equal 'Material  Title', @material.title
    assert_equal 'https://material.com', @material.url
  end

  test 'archived?' do
    assert materials(:material_with_external_resource).archived?
    refute materials(:material_with_suggestions).archived?
    refute materials(:bad_material).archived?
    refute Material.new.archived?
  end

  test 'can set nodes using case insensitive names' do
    @material.node_names = ['ignore me', 'test node', '  WeSTeRoS', 'Ignore me', '']
    assert_equal ['Test Node', 'Westeros'], @material.nodes.map(&:name)
  end
end
