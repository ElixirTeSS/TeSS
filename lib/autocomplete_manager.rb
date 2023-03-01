# From http://pastebin.com/4p6aN7n0
# in lib/tess/keyword_manager.rb
module AutocompleteManager
  def self.included(mod)
    mod.extend(ClassMethods)
  end

  module ClassMethods
    def update_suggestions(*fields)
      cattr_accessor :suggestion_fields_to_add
      self.suggestion_fields_to_add= fields

      before_save :add_suggestions
      before_destroy :delete_suggestions
      include AutocompleteManager::InstanceMethods
    end
  end

  module InstanceMethods
    private
    def add_suggestions
      self.class.suggestion_fields_to_add.each do |field|
        AutocompleteSuggestion.add(field, self[field])
      end
    end

    def delete_suggestions
      # pass
    end
  end
end

# end of lib/keyword_manager.rb

# in your model:
#   class SomeModel < ApplicationRecord
#     add_keywords(:keywords)
#     delete_keywords(:keywords)
#   end