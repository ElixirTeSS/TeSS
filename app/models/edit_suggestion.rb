class EditSuggestion < ActiveRecord::Base
  belongs_to :material
  has_many :scientific_topics, dependent: :nullify
end
