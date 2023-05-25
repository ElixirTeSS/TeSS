# frozen_string_literal: true

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

    assert_equal content_provider.node, nodes(:good)
  end

  test 'should have contact' do
    # not added
    refute_nil content_providers(:organisation_provider)
    assert_nil content_providers(:organisation_provider).contact

    # blank
    refute_nil content_providers(:project_provider)
    refute_nil content_providers(:project_provider).contact
    assert content_providers(:project_provider).contact.blank?

    # just email
    refute_nil content_providers(:another_portal_provider)
    refute_nil content_providers(:another_portal_provider).contact
    assert_equal 'user@provider.portal',
                 content_providers(:another_portal_provider).contact

    # name and email
    refute_nil content_providers(:portal_provider)
    refute_nil content_providers(:portal_provider).contact
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
end
