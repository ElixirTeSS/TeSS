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

end
