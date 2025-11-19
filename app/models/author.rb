class Author < ApplicationRecord
  has_many :material_authors, dependent: :destroy
  has_many :materials, through: :material_authors

  validates :first_name, :last_name, presence: true

  def full_name
    "#{first_name} #{last_name}".strip
  end
end
