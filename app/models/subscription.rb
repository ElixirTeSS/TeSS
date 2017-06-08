class Subscription < ActiveRecord::Base

  FREQUENCY = {
      daily: 1,
      weekly: 2,
      monthly: 3
  }.with_indifferent_access.freeze

  INV_FREQUENCY = FREQUENCY.symbolize_keys.invert.freeze

  PERIODS = {
      daily: 1.day,
      weekly: 1.week,
      monthly: 1.month
  }.freeze

  validates :frequency, presence: true, inclusion: { in: INV_FREQUENCY.values }
  validates :subscribable_type, presence: true
  validate :valid_subscribable_type
  belongs_to :user

  before_create :set_last_checked_at

  def frequency
    INV_FREQUENCY[super]
  end

  def frequency= freq
    super(FREQUENCY[freq])
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

    type.search_and_filter(user, query, facets, per_page: 15, max_age: period).results
  end

  def period
    PERIODS[frequency]
  end

  def due?
    last_checked_at < (Time.now - period)
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
    clause = PERIODS.map do |freq, period|
      "(frequency = '#{FREQUENCY[freq]}' AND last_checked_at < '#{period.ago}')"
    end.join(' OR ')

    where(clause)
  end

  private

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
