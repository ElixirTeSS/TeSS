require 'test_helper'

class ContentProviderTest < ActiveSupport::TestCase

  setup do
    mock_images
  end

  test 'should not save invalid content provider' do
    content_provider = ContentProvider.new
    assert content_provider.invalid?
    assert content_provider.errors[:title].any?
    assert content_provider.errors[:url].any?
  end

  test 'should allow empty image_url' do
    content_provider = content_providers(:provider_with_empty_image_url)
    assert content_provider.valid?
  end

  test 'should not allow invalid image_url' do
    content_provider = content_providers(:provider_with_invalid_image_url)
    assert content_provider.invalid?
    assert content_provider.errors[:image_url].any?
  end

  test 'should have node' do
    content_provider = content_providers(:goblet)
    assert content_provider.node == nodes(:good)
  end

  test 'should have contact' do
    # not added
    assert !content_providers(:organisation_provider).nil?
    assert content_providers(:organisation_provider).contact.nil?

    # blank
    assert !content_providers(:project_provider).nil?
    assert !content_providers(:project_provider).contact.nil?
    assert content_providers(:project_provider).contact.blank?

    # just email
    assert !content_providers(:another_portal_provider).nil?
    assert !content_providers(:another_portal_provider).contact.nil?
    assert_equal 'user@provider.portal',
                 content_providers(:another_portal_provider).contact

    # name and email
    assert !content_providers(:portal_provider).nil?
    assert !content_providers(:portal_provider).contact.nil?
    assert_equal 'Jim (jim@provider.portal)',
                 content_providers(:portal_provider).contact

  end

  test 'should validate content provider type' do
    content_provider = ContentProvider.new(title: 'New Provider',
                                           url: 'https://website.internet',
                                           user: users(:regular_user),
                                           content_provider_type: 'Something')
    refute content_provider.valid?
    assert content_provider.errors.added?(:content_provider_type, :inclusion, value: 'Something')

    content_provider.content_provider_type = 'Organisation'
    assert content_provider.valid?
  end

  test 'should strip attributes' do
    mock_images
    WebMock.stub_request(:any, 'http://website.com').to_return(status: 200, body: 'hi')
    content_provider = content_providers(:goblet)
    assert content_provider.update(title: ' Provider  Title  ',
                                   url: "\t  \t  http://website.com ",
                                   image_url: " http://image.host/another_image.png\n")
    assert_equal 'Provider  Title', content_provider.title
    assert_equal 'http://website.com', content_provider.url
    assert_equal 'http://image.host/another_image.png', content_provider.image_url
  end

  test 'should correctly destroy associated items when destroyed' do
    content_provider = content_providers(:goblet)
    material = materials(:material_with_external_resource)
    event = events(:event_with_external_resource)
    learning_path = learning_paths(:one)
    learning_path.update!(content_provider: content_provider)
    source = sources(:first_source)
    source.update!(content_provider: content_provider)

    material_count = content_provider.materials.count
    event_count = content_provider.events.count
    learning_path_count = content_provider.learning_paths.count
    source_count = content_provider.sources.count

    assert_difference('Material.count', -material_count) do
      assert_difference('Event.count', -event_count) do
        assert_difference('LearningPath.count', -learning_path_count) do
          assert_difference('Source.count', -source_count) do
            content_provider.destroy!
          end
        end
      end
    end

    assert_nil Material.find_by_id(material.id)
    assert_nil Event.find_by_id(event.id)
    assert_nil LearningPath.find_by_id(learning_path.id)
    assert_nil Source.find_by_id(source.id)
  end
end
