# frozen_string_literal: true

require 'private_address_check'
require 'private_address_check/tcpsocket_ext'

module HasImage
  def self.included(mod)
    mod.extend(ClassMethods)
  end

  module ClassMethods
    def has_image(placeholder:)
      has_attached_file :image, styles: { media: '150x150>' }, default_url: placeholder

      validates_attachment_content_type :image, content_type: %r{\Aimage/.*\Z}
      validates :image_url, url: true, allow_blank: true

      before_validation :resolve_image_url
      include HasImage::InstanceMethods
    end
  end

  module InstanceMethods
    private

    def resolve_image_url
      return if image_url.blank?

      # Download the image from the given URL if no image file provided or if URL was changed.
      if !image? || image_url_changed?
        begin
          uri = URI.parse(image_url)
          return unless uri.absolute? # Error message will be added by the `image_url` validator

          #
          # if PrivateAddressCheck.resolves_to_private_address?(uri.host)
          #   self.errors.add(:image_url, 'is not accessible')
          #   return
          # end

          PrivateAddressCheck.only_public_connections do
            self.image = uri
          end

          # NOTE! The two lines below are needed because Paperclip validates the image on assignment, and then again
          #  when the actual validations are run, resulting in duplicate error messages!
          errors.delete(:image)
          errors.delete(:image_content_type)
        rescue URI::InvalidURIError
          nil
        rescue Errno::ECONNREFUSED, OpenURI::HTTPError, OpenSSL::SSL::SSLError
          errors.add(:image_url, 'could not be accessed')
        rescue PrivateAddressCheck::PrivateConnectionAttemptedError
          errors.add(:image_url, 'could not be accessed') # Keep the error message the same as above
        end
      elsif image.dirty? # Clear the URL if there was a file provided (as it won't match the file anymore)
        self.image_url = nil
      end
    end
  end
end
