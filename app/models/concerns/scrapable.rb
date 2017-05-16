module Scrapable

  extend ActiveSupport::Concern

  THRESHOLD = 2.days.freeze

  def stale?
    last_scraped && (last_scraped < THRESHOLD.ago)
  end

end
