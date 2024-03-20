class LlmObject < ApplicationRecord
  belongs_to :event
  validates :scrape_or_process, presence: true
  validates :model, presence: true
  validates :prompt, presence: true
  validates :input, presence: true
  validates :output, presence: true
end
