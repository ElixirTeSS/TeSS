class PersonLink < ApplicationRecord
  belongs_to :resource, polymorphic: true
  belongs_to :person
  accepts_nested_attributes_for :person, reject_if: :all_blank

  validates :resource, :person, :role, presence: true
end
