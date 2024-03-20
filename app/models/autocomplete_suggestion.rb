# frozen_string_literal: true

class AutocompleteSuggestion < ApplicationRecord
  def self.add(field, *suggestions)
    suggestions = clean(suggestions)
    upsert_all(suggestions.map { |s| { field:, value: s } }, unique_by: %i[field value]) if suggestions.any?
  end

  def self.people
    where(field: %w[authors contributors])
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
    suggestions = clean(suggestions)
    add(field, *suggestions)
    redundant = where(field:).where.not(value: suggestions)
    count = redundant.count
    redundant.destroy_all if count.positive?
    count
  end

  def self.clean(suggestions)
    suggestions.map(&:strip)
  end
end
