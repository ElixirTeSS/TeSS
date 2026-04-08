module RSS
  module Atom
    Feed.install_ns(MEDIA_PREFIX, MEDIA_URI)

    class Feed
      include MediaGroupDescriptionModel
      class Entry
        include MediaGroupDescriptionModel

        class MediaGroup < Element
          include RSS09

          @tag_name = 'group'

          class << self
            def required_prefix
              MEDIA_PREFIX
            end

            def required_uri
              MEDIA_URI
            end
          end

          install_must_call_validator(MEDIA_PREFIX, MEDIA_URI)
          install_text_element('title', MEDIA_URI, '?', 'media_title')
          install_text_element('description', MEDIA_URI, '?', 'media_description')
        end
      end
    end

    class Entry
      include MediaGroupDescriptionModel
    end
  end
end
