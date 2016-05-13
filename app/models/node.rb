class Node < ActiveRecord::Base

  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :user
  has_many :staff_members

  # name:string
  # member_status:string
  # country_code:string
  # home_page:string
  # institutions:array
  # twitter:string
  # carousel_images:array

  validates :name, presence: true
  validates :home_page, presence: true
  validates :home_page, format: { with: URI.regexp }, if: Proc.new { |a| a.home_page.present? }

end
