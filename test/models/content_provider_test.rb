require 'test_helper'

class ContentProviderTest < ActiveSupport::TestCase

  setup do
    mock_images
  end

  # test "the truth" do
  #   assert true
  # end
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

  test 'should fetch remote image' do
    provider = content_providers(:goblet)

    assert provider.image_url
    refute provider.image?

    provider.save

    assert provider.image?
    assert (provider.image.size > 0)
    assert !provider.image.url.blank?
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
    assert (provider.image.size > 0)
    assert !provider.image.url.blank?
  end

  test 'should replace image when URL changed' do
    provider = content_providers(:goblet)
    provider.save
    old_size = provider.image.size
    old_url = provider.image.url

    provider.image_url = 'http://image.host/another_image.png'
    provider.save

    assert_not_equal old_size, provider.image.size
    assert_not_equal old_url, provider.image.url
  end

  test 'should replace file image when URL first provided' do
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
