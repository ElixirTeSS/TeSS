class MaterialAuthor < ApplicationRecord
  belongs_to :material
  belongs_to :author

  validates :material, :author, presence: true
end
