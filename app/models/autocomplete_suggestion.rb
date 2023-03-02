class AutocompleteSuggestion < ApplicationRecord
  def self.add(field, *suggestions)
    upsert_all(suggestions.map { |s| { field: field, value: s } }, unique_by: [:field, :value]) if suggestions.any?
  end

  def self.people
    where(field: ['authors', 'contributors'])
  end

  def self.starting_with(query)
    where('lower(value) LIKE ?', "#{query.downcase}%")
  end

  def self.query(query, limit = nil)
    q = starting_with(query)
    q = q.limit(limit) if limit
    q.order(value: :asc).pluck(:value)
  end

  def self.refresh(field, *suggestions)
    add(field, *suggestions)
    redundant = where(field: field).where.not(value: suggestions)
    count = redundant.count
    redundant.destroy_all if count > 0
    count
  end
end
