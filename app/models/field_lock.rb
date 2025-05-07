class FieldLock < ApplicationRecord

  belongs_to :resource, polymorphic: true
  validates :field, presence: true

  ALIASES = {
    node_ids: [:node_names]
  }.freeze

  def self.strip_locked_fields(params, locked_fields)
    locked_fields.each do |field|
      params.delete(field)
      ALIASES[field]&.each do |field_alias|
        params.delete(field_alias)
      end
    end
  end
end
