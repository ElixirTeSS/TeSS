require 'test_helper'

class ImageAttachmentTest < ActiveSupport::TestCase

  setup do
    mock_images
  end

  test 'should fetch remote image' do
    provider = content_providers(:goblet)

    assert provider.image_url
    refute provider.image?

    provider.save

    assert provider.image?
    assert provider.image.size > 0
    refute provider.image_url.blank?
  end

  test 'should clear image URL when file uploaded' do
    provider = content_providers(:goblet)

    assert provider.image_url
    refute provider.image?

    provider.image = File.new(File.join(Rails.root, 'test/fixtures/files/image.png'))
    provider.save

    assert provider.image_url.blank?
    assert provider.image?
    assert provider.image.size > 0
  end

  test 'should replace URL-sourced image when URL changed' do
    provider = content_providers(:goblet)
    provider.save
    old_size = provider.image.size
    old_url = provider.image.url

    provider.image_url = 'http://image.host/another_image.png'
    provider.save

    assert_not_equal old_size, provider.image.size
    assert_not_equal old_url, provider.image.url
  end

  test 'should replace file-sourced image when URL provided' do
    provider = content_providers(:provider_with_empty_image_url)
    provider.save
    provider.image = File.new(File.join(Rails.root, 'test/fixtures/files/image.png'))
    provider.save

    old_size = provider.image.size
    old_url = provider.image.url

    provider.image_url = 'http://image.host/another_image.png'
    provider.save

    assert_not_equal old_size, provider.image.size
    assert_not_equal old_url, provider.image.url
  end

end
