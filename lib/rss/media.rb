require 'rss/atom'

module RSS
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

require_relative 'media/atom'
