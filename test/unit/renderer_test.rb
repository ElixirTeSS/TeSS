require 'test_helper'

class RendererTest < ActiveSupport::TestCase
  VALID_YOUTUBE_URLS = %w(https://youtu.be/abcd1234_-z?list=ABC123XYZQQQ
    http://www.youtube.com/watch?v=abcd1234_-z&feature=youtu.be
    http://youtu.be/abcd1234_-z&feature=channel
    http://www.youtube.com/ytscreeningroom?v=abcd1234_-z
    http://www.youtube.com/embed/abcd1234_-z?rel=0
    http://youtube.com/?v=abcd1234_-z&feature=channel
    http://youtube.com/?feature=channel&v=abcd1234_-z
    http://youtube.com/?vi=abcd1234_-z&feature=channel
    http://youtube.com/watch?v=abcd1234_-z&feature=channel
    http://youtube.com/watch?vi=abcd1234_-z&feature=channel
    https://m.youtube.com/watch?v=abcd1234_-z
    https://www.youtube.com/watch?app=desktop&v=abcd1234_-z
    https://m.youtube.com/watch?app=desktop&v=abcd1234_-z).freeze

  INVALID_YOUTUBE_URLS = %w(https://youtu.fi/abcd1234_-z?list=ABC123XYZQQQ
    http://www.boutube.com/watch?v=abcd1234_-z&feature=youtu.be
    http://elixir.be/abcd1234_-z&feature=channel
    http://www.youtube.biz/embed/abcd1234_-z?rel=0
    http://youtube.com/c/abcd1234_-z
    ftp://youtube.com/?v=abcd1234_-z).freeze

  setup do
    @resource = materials(:youtube_video_material)
    @renderer = Renderers::Youtube.new(@resource)
  end

  test 'extract video code' do
    VALID_YOUTUBE_URLS.each do |url|
      assert_equal 'abcd1234_-z', @renderer.extract_video_code(url), "Failed to extract code from: #{url}"
    end

    INVALID_YOUTUBE_URLS.each do |url|
      assert_nil @renderer.extract_video_code(url), "Wrongly extracted code from invalid URL: #{url}"
    end
  end

  test 'can render?' do
    assert @renderer.can_render?
    refute Renderers::Youtube.new(materials(:good_material)).can_render?
    refute Renderers::Youtube.new(materials(:bad_material)).can_render?
  end

  test 'render content' do
    content = @renderer.render_content
    assert content.html_safe?
    assert content.start_with?('<iframe width="560" height="315" src="https://www.youtube.com/embed/1T_2xMTQCv4"')
    assert content.end_with?('</iframe>')
  end
end
