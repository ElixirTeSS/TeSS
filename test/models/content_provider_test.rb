require 'test_helper'

class ContentProviderTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test 'should not save invalid url for image_url' do
    content_provider = ContentProvider.new
    assert content_provider.invalid?
    assert content_provider.errors[:title].any?
    assert content_provider.errors[:url].any?
    assert content_provider.errors[:image_url].any?
  end

end
