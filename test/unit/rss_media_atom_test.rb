require 'test_helper'

class RSSMediaAtomTest < ActiveSupport::TestCase
  test 'install_media_namespace! is idempotent for the media prefix' do
    assert_nothing_raised do
      RSS::Media::Atom.install_media_namespace!
      RSS::Media::Atom.install_media_namespace!
    end

    assert_equal RSS::Media::MEDIA_URI, RSS::Atom::Feed::NSPOOL[RSS::Media::MEDIA_PREFIX]
  end
end
