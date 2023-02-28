# From http://pastebin.com/4p6aN7n0
# in lib/tess/keyword_manager.rb
module AutocompleteManager
  def self.included(mod)
    mod.extend(ClassMethods)
  end

  def self.suggestions_array_for(type)
    path = file_path(type)
    return [] unless File.exist?(path)
    File.readlines(path, chomp: true).uniq
  end

  def self.suggestions(type, query, limit = 20)
    found = []
    suggestions_array_for(type).each do |a|
      found << a if a.start_with?(query)
      return found if found.length >= limit
    end
    found
  end

  def self.file_path(type)
    Rails.root.join('lib', 'assets', "#{type}_suggestions.txt")
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
            file = File.open(AutocompleteManager.file_path(field), 'a')
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