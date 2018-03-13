require 'test_helper'

class ImageAttachmentTest < ActiveSupport::TestCase

  setup do
    mock_images
  end

  test 'should fetch remote image' do
    provider = content_providers(:goblet)

    assert provider.image_url
    refute provider.image?

    assert provider.save

    assert provider.image?
    assert provider.image.size > 0
    refute provider.image_url.blank?
  end

  test 'should clear image URL when file uploaded' do
    provider = content_providers(:goblet)

    assert provider.image_url
    refute provider.image?

    provider.image = File.new(File.join(Rails.root, 'test/fixtures/files/image.png'))
    assert provider.save

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
    assert provider.save

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
    assert provider.save

    assert_not_equal old_size, provider.image.size
    assert_not_equal old_url, provider.image.url
  end

  test 'should not parse junk URL' do
    provider = content_providers(:goblet)
    provider.image_url = 'qwerty'

    refute provider.save

    assert_equal 1, provider.errors[:image_url].length
    assert provider.errors[:image_url].first.include?('not a valid')
  end

  test 'should gracefully handle 404 image URL' do
    provider = content_providers(:goblet)
    provider.image_url = 'http://404.host/image.png'

    refute provider.save

    assert_equal 1, provider.errors[:image_url].length
    assert provider.errors[:image_url].first.include?('could not be accessed')
  end

  test 'should not store non-image file' do
    provider = content_providers(:goblet)
    provider.image_url = 'http://text.host/text.txt'

    refute provider.save

    assert_equal 1, provider.errors[:image].length
    assert provider.errors[:image].first.include?('invalid')
  end

  test 'should not store potentially malicious non-image file' do
    provider = content_providers(:goblet)
    provider.image_url = 'http://malicious.host/image.png'

    refute provider.save

    assert_equal 1, provider.errors[:image].length
    assert provider.errors[:image].first.include?('contents that are not what they are reported to be')
  end

  test 'should not permit internal image URL address' do
    provider = content_providers(:goblet)
    provider.image_url = 'http://127.0.0.1/image.png'

    refute provider.save

    assert_equal 1, provider.errors[:image_url].length
    assert provider.errors[:image_url].first.include?('could not be accessed')
  end
end
