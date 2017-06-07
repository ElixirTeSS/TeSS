class Subscription < ActiveRecord::Base

  FREQUENCY = {
      daily: 1,
      weekly: 2,
      monthly: 3
  }.with_indifferent_access.freeze

  INV_FREQUENCY = FREQUENCY.symbolize_keys.invert.freeze

  validates :frequency, presence: true, inclusion: { in: INV_FREQUENCY.values }
  validates :subscribable_type, presence: true
  validate :valid_subscribable_type
  belongs_to :user

  def frequency
    INV_FREQUENCY[super]
  end

  def frequency= freq
    super(FREQUENCY[freq])
  end

  def unsubscribe_code
    unsubscribe_verifier.generate(self.id)
  end

  def valid_unsubscribe_code?(code)
    unsubscribe_verifier.verify(code) == self.id
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    false
  end

  def digest
    type = subscribable_type.constantize

    type.search_and_filter(user, query, facets, max_age: period)
  end

  def period
    case frequency
      when :daily
        1.day
      when :weekly
        1.week
      when :monthly
        1.month
    end
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

end
