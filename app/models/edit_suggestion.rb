class EditSuggestion < ActiveRecord::Base
  has_one :material, dependent: :nullify
  has_many :scientific_topics, dependent: :nullify
end
