class SourceFilter < ApplicationRecord
  belongs_to :source

  enum filter_by: {
    target_audience: 'target_audience',
    keyword: 'keyword'
  }

  enum filter_mode: {
    allow: 'allow',
    block: 'block'
  }
end
