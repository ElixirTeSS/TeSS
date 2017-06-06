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

end
