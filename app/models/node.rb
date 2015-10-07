class Node < ActiveRecord::Base

  # name:string
  # member_status:string
  # country_code:string
  # home_page:string
  # institutions:array
  # trc:string
  # trc_email:string
  # trc:image:string
  # staff:array
  # twitter:string
  # carousel_images:array

  validates :name, presence: true
  validates :home_page, presence: true
  validates :home_page, format: { with: URI.regexp }, if: Proc.new { |a| a.home_page.present? }

end
