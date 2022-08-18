module FuzzyDictionaryMatch
  def self.included(mod)
    mod.extend(ClassMethods)
  end

  module ClassMethods
    # Remove empty array elements
    def fuzzy_dictionary_match(fields)
      cattr_accessor :fields_to_match

      self.fields_to_match ||= {}
      self.fields_to_match.merge!(fields)

      before_validation :match_fields

      include FuzzyDictionaryMatch::InstanceMethods
    end
  end

  module InstanceMethods
    private

    def match_fields
      self.class.fields_to_match.each do |field, dictionary|
        if self[field].instance_of? Array
          self[field].map! do |n|
            dictionary.best_match(n) || n
          end
        else
          self[field] = dictionary.best_match(self[field]) || self[field]
        end
      end
    end
  end
end

# in your model:
#   class SomeModel < ApplicationRecord
#     include FuzzyDictionaryMatch
#     fuzzy_dictionary_match(event_types: EventTypeDictionary.instance)
#   end
