# Patches RSS::Atom::Feed and RSS::Atom::Entry with Media namespace support (see ../media.rb).
# Kept as RSS::Media::Atom so Zeitwerk can autoload it from lib/rss/media/atom.rb.
module RSS
  module Media
    module Atom
      def self.install_media_namespace!
        # This extension can be evaluated more than once in reloader/autoload flows.
        # RSS::Element.install_ns raises on duplicate prefixes, so treat same mapping as a no-op.
        ns_pool = ::RSS::Atom::Feed::NSPOOL
        existing_uri = ns_pool[MEDIA_PREFIX]

        return if existing_uri == MEDIA_URI

        raise ::RSS::OverlappedPrefixError, MEDIA_PREFIX unless existing_uri.nil?

        ::RSS::Atom::Feed.install_ns(MEDIA_PREFIX, MEDIA_URI)
      end

      install_media_namespace!

      class ::RSS::Atom::Feed
        include ::RSS::Media::MediaGroupDescriptionModel

        class Entry
          include ::RSS::Media::MediaGroupDescriptionModel

          class MediaGroup < Element
            include RSS09

            @tag_name = 'group'

            class << self
              def required_prefix
                ::RSS::Media::MEDIA_PREFIX
              end

              def required_uri
                ::RSS::Media::MEDIA_URI
              end
            end

            install_must_call_validator(::RSS::Media::MEDIA_PREFIX, ::RSS::Media::MEDIA_URI)
            install_text_element('title', ::RSS::Media::MEDIA_URI, '?', 'media_title')
            install_text_element('description', ::RSS::Media::MEDIA_URI, '?', 'media_description')
          end
        end
      end

      class ::RSS::Atom::Entry
        include ::RSS::Media::MediaGroupDescriptionModel
      end
    end
  end
end
