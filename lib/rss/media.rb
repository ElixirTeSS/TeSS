# Extension for the Yahoo Media RSS namespace (xmlns:media="http://search.yahoo.com/mrss/").
# Used by feeds that carry rich media metadata, e.g. YouTube channel feeds which include
# <media:group>, <media:title>, and <media:description> elements.
#
# The extension is structured as RSS::Media (rather than a flat module inside RSS) so that
# Zeitwerk can autoload it correctly from lib/rss/media.rb.
require 'rss/atom'

module RSS
  module Media
    MEDIA_PREFIX = 'media'
    MEDIA_URI = 'http://search.yahoo.com/mrss/'

    module MediaGroupDescriptionModel
      extend ::RSS::BaseModel

      def self.append_features(klass)
        super
        return if klass.instance_of?(Module)

        klass.install_must_call_validator(MEDIA_PREFIX, MEDIA_URI)
        klass.install_have_child_element('group', MEDIA_URI, '?', 'media_group')
      end
    end

    ::RSS::BaseListener.install_class_name(MEDIA_URI, 'group', 'MediaGroup')
    ::RSS::BaseListener.install_get_text_element(MEDIA_URI, 'title', 'media_title')
    ::RSS::BaseListener.install_get_text_element(MEDIA_URI, 'description', 'media_description')
  end
end

require_relative 'media/atom'
