class Editor < ApplicationRecord
  belongs_to :content_provider
  belongs_to :user
end