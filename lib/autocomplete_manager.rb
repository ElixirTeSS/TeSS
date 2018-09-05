# From http://pastebin.com/4p6aN7n0
# in lib/tess/keyword_manager.rb
module AutocompleteManager

  def self.included(mod)
    mod.extend(ClassMethods)
  end

  def self.suggestions_file_for(field_name, access='r')
    file_path = Rails.root.join('lib', 'assets', "#{field_name}_suggestions.txt").to_s
    if !File.exists?(file_path)
      a = File.open(file_path, 'w')
      a.close
    end
    File.open(file_path, access)
  end

  def self.suggestions_array_for(type)
    k = suggestions_file_for(type, 'r')
    words = k.read.split("\n").uniq
    k.close
    return words
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
        suggestions = AutocompleteManager.suggestions_array_for(field)
        new_suggestions = self[field].dup
        new_suggestions.each do |suggestion|
          unless suggestions.include?(suggestion)
            file = AutocompleteManager.suggestions_file_for(field, 'a+')
            file << "#{suggestion}\n"
            file.close
          end
        end
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