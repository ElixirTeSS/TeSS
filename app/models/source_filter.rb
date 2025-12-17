class SourceFilter < ApplicationRecord
  belongs_to :source

  enum :filter_by, {
    target_audience: 'target_audience',
    keyword: 'keyword'
  }

  enum :filter_mode, {
    allow: 'allow',
    block: 'block'
  }

  def match(item)
    return false unless item.respond_to?(filter_property)

    # array properties
    return unless %w[target_audience keywords].include?(filter_property)

    item.send(filter_property).any? do |i|
      i == filter_value
    end
  end

  def filter_property
    return 'keywords' if keyword?

    filter_by
  end
end
