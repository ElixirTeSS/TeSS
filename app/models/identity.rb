class Identity < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true
  validates :uid, uniqueness: { scope: :provider }, allow_nil: true

  def self.from_omniauth(auth)
    Identity.where(provider: auth.provider, uid: auth.uid).first_or_initialize
  end
end
