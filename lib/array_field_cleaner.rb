# frozen_string_literal: true

# From http://pastebin.com/4p6aN7n0
# in lib/tess/array_field_cleaner.rb
module ArrayFieldCleaner
  def self.included(mod)
    mod.extend(ClassMethods)
  end

  module ClassMethods
    # Remove empty array elements
    def clean_array_fields(*fields)
      cattr_accessor :fields_to_clean

      self.fields_to_clean = fields

      before_validation :clean_fields

      include ArrayFieldCleaner::InstanceMethods
    end
  end

  module InstanceMethods
    private

    def clean_fields
      self.class.fields_to_clean.each do |field|
        self[field] = if self[field].nil?
                        []
                      else
                        self[field].reject(&:blank?).map(&:strip)
                      end
      end
    end
  end
end
# end of lib/array_field_cleaner.rb

# in your model:
#   class SomeModel < ApplicationRecord
#     clean_array_fields(:keywords, :contributors, :pigs)
#   end
