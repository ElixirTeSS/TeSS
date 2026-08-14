module Scrapable

  extend ActiveSupport::Concern

  included do
    belongs_to :last_scraped_by_source, class_name: 'Source', foreign_key: :last_scraped_by_id, optional: true
  end

  THRESHOLD = 2.days.freeze

  def stale?
    last_scraped && (last_scraped < THRESHOLD.ago)
  end

end
