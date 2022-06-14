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

end
