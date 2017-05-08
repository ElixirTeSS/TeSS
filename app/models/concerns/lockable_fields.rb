module LockableFields

  extend ActiveSupport::Concern

  included do
    has_many :field_locks, as: :resource, dependent: :destroy
  end

  def locked_fields
    field_locks.map { |l| l.field.to_sym }
  end

  def locked_fields=(fields)
    self.field_locks = fields.reject(&:blank?).uniq.map { |f| field_locks.build(field: f.to_s) }
  end

  def field_locked?(field)
    field_locks.where(field: field).any?
  end

end
