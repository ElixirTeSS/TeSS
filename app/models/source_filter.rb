
module FilterComparisons
  def self.string_match(content_value, filter_value)
    content_value.to_s.casecmp?(filter_value)
  end

  def self.prefix_string_match(content_value, filter_value)
    content_value.to_s.downcase.start_with?(filter_value.downcase)
  end

  def self.contains_string_match(content_value, filter_value)
    content_value.to_s.downcase.include?(filter_Value.downcase)
  end

  def self.array_string_match(content_value, filter_value)
    return false if content_value.nil?
    content_value.any? { |i| i.to_s.casecmp?(filter_value) }
  end
end


FILTER_DEFINITIONS = {
  'target_audience' => {
    comparison: FilterComparisons.method(:array_string_match)
  },

  'keyword' => {
    comparison: FilterComparisons.method(:array_string_match),
    filter_property: 'keywords'
  },

  'title' => {
    comparison: FilterComparisons.method(:string_match)
  },

  'title_contains' => {
    comparison: FilterComparisons.method(:contains_string_match),
    filter_property: 'title'
  },

  'description' => {
    comparison: FilterComparisons.method(:string_match)
  },

  'description_contains' => {
    comparison: FilterComparisons.method(:contains_string_match),
    filter_property: 'description'
  },

  'url' => {
    comparison: FilterComparisons.method(:string_match)
  },

  'url_prefix' => {
    comparison: FilterComparisons.method(:prefix_string_match),
    filter_property: 'url'
  },

  'doi' => {
    comparison: FilterComparisons.method(:string_match)
  },

  'license' => {
    comparison: FilterComparisons.method(:string_match),
    filter_property: 'licence'
  },

  'difficulty_level' => {
    comparison: FilterComparisons.method(:string_match)
  },

  'resource_type' => {
    comparison: FilterComparisons.method(:array_string_match)
  },

  'prerequisites_contains' => {
    comparison: FilterComparisons.method(:contains_string_match),
    filter_property: 'prerequisites'
  },

  'learning_objectives_contains' => {
    comparison: FilterComparisons.method(:contains_string_match),
    filter_property: 'learning_objectives'
  },

  'subtitle' => {
    comparison: FilterComparisons.method(:string_match)
  },

  'subtitle_contains' => {
    comparison: FilterComparisons.method(:contains_string_match),
    filter_property: 'subtitle'
  },

  'city' => {
    comparison: FilterComparisons.method(:string_match)
  },

  'country' => {
    comparison: FilterComparisons.method(:string_match)
  },

  'event_type' => {
    comparison: FilterComparisons.method(:array_string_match),
    filter_property: 'event_types'
  },

  'timezone' => {
    comparison: FilterComparisons.method(:string_match)
  }
}.freeze


class SourceFilter < ApplicationRecord
  belongs_to :source

  auto_strip_attributes :filter_value
  validates :filter_mode, :filter_by, presence: true

  enum :filter_by, FILTER_DEFINITIONS.keys.index_with(&:itself)

  enum :filter_mode, {
    allow: 'allow',
    block: 'block'
  }

  def match(item)
    val = nil
    val = item.send(filter_property) if item.respond_to?(filter_property)
    filter_definition[:comparison].call(val, filter_value.to_s)
  end

  def filter_definition 
    FILTER_DEFINITIONS[filter_by]
  end

  def filter_property
    filter_definition[:filter_property] || filter_by
  end
end
