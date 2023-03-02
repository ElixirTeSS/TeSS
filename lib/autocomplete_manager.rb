module AutocompleteManager
  def self.included(mod)
    mod.extend(ClassMethods)
  end

  module ClassMethods
    def update_suggestions(*fields)
      cattr_accessor :suggestion_fields_to_add
      self.suggestion_fields_to_add= fields

      after_save :add_suggestions
      include AutocompleteManager::InstanceMethods
    end
  end

  module InstanceMethods
    private
    def add_suggestions
      self.class.suggestion_fields_to_add.each do |field|
        AutocompleteSuggestion.add(field, *self[field])
      end
    end
  end
end
