class ExternalResource < ActiveRecord::Base

  belongs_to :source, polymorphic: true

  validates :title, :url, presence: true
  validates :url, url: true

end
