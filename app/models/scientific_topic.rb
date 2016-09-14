class ScientificTopic < ActiveRecord::Base
  extend FriendlyId
  friendly_id :preferred_label, use: :slugged
  has_many :materials
end
