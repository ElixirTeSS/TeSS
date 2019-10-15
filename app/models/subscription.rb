class Subscription < ApplicationRecord
  CHECK_WINDOW = 1.hour # Window to add to subscription period to avoid synchronization issues with cronjob to process
                        # subscriptions.
                        # e.g. A window of 1 hour will make a daily subscription "due" 23 hours after it was last checked.

  FREQUENCY = [
      { key: :daily, id: 1, period: 1.day, title: '24 hours' }.with_indifferent_access,
      { key: :weekly, id: 2, period: 1.week, title: '1 week' }.with_indifferent_access,
      { key: :monthly, id: 3, period: 1.month, title: '1 month' }.with_indifferent_access
  ].freeze

  validates :frequency, presence: true, inclusion: { in: FREQUENCY.map { |f| f[:key] } }
  validates :subscribable_type, presence: true
  validate :valid_subscribable_type
  belongs_to :user

  before_create :set_last_checked_at

  def frequency
    FREQUENCY.detect { |f| f[:id] == super }.try(:[], :key)
  end

  def frequency= freq
    super(FREQUENCY.detect { |f| f[:key] == freq.to_sym }.try(:[], :id))
  end

  def unsubscribe_code
    unsubscribe_verifier.generate(self.id).split('--').last
  end

  def valid_unsubscribe_code?(code)
    unsubscribe_verifier.verify("#{Base64.encode64(Marshal.dump(self.id)).chomp}--#{code}") == self.id
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    false
  end

  def digest
    type = subscribable_type.constantize

    type.search_and_filter(user, query, facets_with_max_age, per_page: 15).results
  end

  def facets_with_max_age
    facets.merge(max_age: max_age).with_indifferent_access
  end

  def period
    FREQUENCY.detect { |f| f[:id] == self[:frequency] }[:period]
  end

  def due?
    last_checked_at < (period - CHECK_WINDOW).ago
  end

  def check
    update_attribute(:last_checked_at, Time.now)
  end

  def process
    r = digest

    if r.any?
      SubscriptionMailer.digest(self, r).deliver_now
      self.last_sent_at = Time.now # This will be saved when `check` is called below
    end
    check
  end

  def self.due
    clause = FREQUENCY.map do |freq|
      "(frequency = '#{freq[:id]}' AND last_checked_at < '#{freq[:period].ago}')"
    end.join(' OR ')

    where(clause)
  end

  private

  def max_age
    FREQUENCY.detect { |f| f[:id] == self[:frequency] }[:title]
  end

  def valid_subscribable_type
    begin
      type = self.subscribable_type.constantize
    rescue NameError
      type = nil
    end

    unless type && type.respond_to?(:search_and_filter)
      errors.add(:subscribable_type, 'not valid')
    end
  end

  def unsubscribe_verifier
    Rails.application.message_verifier('unsubscribe')
  end

  def set_last_checked_at
    self.last_checked_at = Time.now
  end
end
