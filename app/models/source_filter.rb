class SourceFilter < ApplicationRecord
  belongs_to :source

  auto_strip_attributes :filter_value
  validates :filter_mode, :filter_by, presence: true

  enum :filter_by, {
    target_audience: 'target_audience',
    keyword: 'keyword',
    title: 'title',
    description: 'description',
    description_contains: 'description_contains',
    url: 'url',
    url_prefix: 'url_prefix',
    doi: 'doi',
    license: 'license',
    difficulty_level: 'difficulty_level',
    resource_type: 'resource_type',
    prerequisites_contains: 'prerequisites_contains',
    learning_objectives_contains: 'learning_objectives_contains',
    subtitle: 'subtitle',
    subtitle_contains: 'subtitle_contains',
    city: 'city',
    country: 'country',
    event_type: 'event_type',
    timezone: 'timezone'
  }

  enum :filter_mode, {
    allow: 'allow',
    block: 'block'
  }

  def match(item)
    return false unless item.respond_to?(filter_property)

    val = item.send(filter_property)

    # string match
    if %w[title url doi description license difficulty_level subtitle city country timezone].include?(filter_by)
      val.to_s.casecmp(filter_value).zero?
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
