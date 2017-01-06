class EditSuggestion < ActiveRecord::Base
  has_one :material
  has_many :scientific_topics
end
