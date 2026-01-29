
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
    content_value.any? { |i| i.to_s.casecmp?(filter_value) }
  end
end

FILTER_DEFINITIONS = {
  'target_audience' => {
    enum_value: 'target_audience',
    comparison: FilterComparisons.method(:array_string_match)
  },
  keyword: {
    enum_value: 'keyword',
    comparison: FilterComparisons.method(:array_string_match),
    filter_property: 'keywords'
  },
  title: {
    enum_value: 'title',
    comparison: FilterComparisons.method(:string_match)
  },
  title_contains: {
    enum_value: 'title_contains',
    comparison: FilterComparisons.method(:contains_string_match)
  },
  description: {
    enum_value: 'description',
    comparison: FilterComparisons.method(:string_match)
  },
  description_contains: {
    enum_value: 'description_contains',
    comparison: FilterComparisons.method(:contains_string_match),
    filter_property: 'description'
  },
  url: {
    enum_value: 'url',
    comparison: FilterComparisons.method(:string_match)
  },
  url_prefix: {
    enum_value: 'url_prefix',
    comparison: FilterComparisons.method(:prefix_string_match),
    filter_property: 'url'
  },
  doi: {
    enum_value: 'doi',
    comparison: FilterComparisons.method(:string_match)
  },
  license: {
    enum_value: 'license',
    comparison: FilterComparisons.method(:string_match),
    filter_property: 'licence'
  },
  difficulty_level: {
    enum_value: 'difficulty_level',
    comparison: FilterComparisons.method(:string_match)
  },
  resource_type: {
    enum_value: 'resource_type',
    comparison: FilterComparisons.method(:array_string_match)
  },
  prerequisites_contains: {
    enum_value: 'prerequisites_contains',
    comparison: FilterComparisons.method(:contains_string_match),
    filter_property: 'prerequisites'
  },
  learning_objectives_contains: {
    enum_value: 'learning_objectives_contains',
    comparison: FilterComparisons.method(:contains_string_match),
    filter_property: 'learning_objectives'
  },
  subtitle: {
    enum_value: 'subtitle',
    comparison: FilterComparisons.method(:string_match)
  },
  subtitle_contains: {
    enum_value: 'subtitle_contains',
    comparison: FilterComparisons.method(:contains_string_match),
    filter_property: 'subtitle'
  },
  city: {
    enum_value: 'city',
    comparison: FilterComparisons.method(:string_match)
  },
  country: {
    enum_value: 'country',
    comparison: FilterComparisons.method(:string_match)
  },
  event_type: {
    enum_value: 'event_type',
    comparison: FilterComparisons.method(:array_string_match),
    filter_property: 'event_types'
  },
  timezone: {
    enum_value: 'timezone',
    comparison: FilterComparisons.method(:string_match)
  }
}.freeze

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
    return false unless item.respond_to?(filter_property)

    val = item.send(filter_property)

    # string match
    if %w[title url doi description license difficulty_level subtitle city country timezone].include?(filter_by)
      val.to_s.casecmp?(filter_value)
    # prefix string match
    elsif %w[url_prefix].include?(filter_by)
      val.to_s.downcase.start_with?(filter_value.downcase)
    # contains string match
    elsif %w[description_contains prerequisites_contains learning_objectives_contains subtitle_contains].include?(filter_by)
      val.to_s.downcase.include?(filter_value.downcase)
    # array string match
    elsif %w[target_audience keyword resource_type event_type].include?(filter_by)
      val.any? { |i| i.to_s.casecmp?(filter_value) }
    else
      false
    end
  end

  def filter_property

    {
      'event_type' => 'event_types',
      'keyword' => 'keywords',
      'url_prefix' => 'url',
      'description_contains' => 'description',
      'prerequisites_contains' => 'prerequisites',
      'learning_objectives_contains' => 'learning_objectives',
      'subtitle_contains' => 'subtitle',
      'license' => 'licence'
    }.fetch(filter_by, filter_by)
  end
end
