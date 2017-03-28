class EditSuggestion < ActiveRecord::Base
  belongs_to :suggestible, polymorphic: true

  include HasScientificTopics
end
