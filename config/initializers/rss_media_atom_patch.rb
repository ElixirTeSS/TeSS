require 'rss'
require 'rss/atom'

# Extension for the Yahoo Media RSS namespace (xmlns:media="http://search.yahoo.com/mrss/").
# Used by feeds that carry rich media metadata, e.g. YouTube channel feeds which include
# <media:group>, <media:title>, and <media:description> elements.

module RSS
  module Media
    MEDIA_PREFIX = 'media'
    MEDIA_URI = 'http://search.yahoo.com/mrss/'

    module MediaGroupDescriptionModel
      extend BaseModel

      def self.append_features(klass)
        super
        return if klass.instance_of?(Module)

        klass.install_must_call_validator(MEDIA_PREFIX, MEDIA_URI)
        klass.install_have_child_element('group', MEDIA_URI, '?', 'media_group')
      end
    end

    BaseListener.install_class_name(MEDIA_URI, 'group', 'MediaGroup')
    BaseListener.install_get_text_element(MEDIA_URI, 'title', 'media_title')
    BaseListener.install_get_text_element(MEDIA_URI, 'description', 'media_description')
  end

  module Atom
    Feed.install_ns(Media::MEDIA_PREFIX, Media::MEDIA_URI)

    class Feed
      include Media::MediaGroupDescriptionModel

      class Entry
        include Media::MediaGroupDescriptionModel

        class MediaGroup < Element
          include RSS09

          @tag_name = 'group'

          class << self
            def required_prefix
              Media::MEDIA_PREFIX
            end

            def required_uri
              Media::MEDIA_URI
            end
          end

          install_must_call_validator(Media::MEDIA_PREFIX, Media::MEDIA_URI)
          install_text_element('title', Media::MEDIA_URI, '?', 'media_title')
          install_text_element('description', Media::MEDIA_URI, '?', 'media_description')
        end
      end
    end
  end
end
