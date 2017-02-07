class EditSuggestion < ActiveRecord::Base
  belongs_to :material
  has_and_belongs_to_many :scientific_topics, dependent: :nullify
end
