class ExternalResource < ActiveRecord::Base

  belongs_to :material

  validates :title, :url, presence: true
  validates :url, url: true

end
