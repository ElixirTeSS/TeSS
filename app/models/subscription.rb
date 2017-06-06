class Subscription < ActiveRecord::Base

  FREQUENCY = {
      daily: 1,
      weekly: 2,
      monthly: 3
  }.with_indifferent_access.freeze

  INV_FREQUENCY = FREQUENCY.symbolize_keys.invert.freeze

  validates :frequency, inclusion: INV_FREQUENCY.values
  belongs_to :user

  def frequency
    INV_FREQUENCY[super]
  end

  def frequency= freq
    super(FREQUENCY[freq])
  end

end
