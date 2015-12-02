class Event < ActiveRecord::Base
  include PublicActivity::Common
  has_paper_trail

  unless SOLR_ENABLED==false
    searchable do
      text :title
      string :title
      text :link
      string :city
      string :provider
      string :sponsor
      string :venue
      string :city
      string :country
      string :field, :multiple => true
      string :category, :multiple => true
      string :keyword, :multiple => true
      time :start
      time :end
      time :updated_at
    end
  end

  has_many :package_events
  has_many :packages, through: :package_events

  validates :title, :link, presence: true

  serialize :field
  serialize :category
  serialize :keyword

  #Make sure there's link and title

  #Generated Event:
  # external_id:string
  # title:string
  # subtitle:string
  # link:string
  # provider:string
  # field:text
  # description:text
  # category:text
  # start:datetime
  # end:datetime
  # sponsor:string
  # venue:text
  # city:string
  # county:string
  # country:string
  # postcode:string
  # latitude:double
  # longitude:double

end
