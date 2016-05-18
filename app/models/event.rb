class Event < ActiveRecord::Base
  include PublicActivity::Common
  has_paper_trail

  extend FriendlyId
  friendly_id :title, use: :slugged

  unless SOLR_ENABLED==false
    searchable do
      text :title
      string :title
      text :url
      string :city
      string :provider
      string :sponsor
      string :venue
      string :city
      string :country
      string :field, :multiple => true
      string :category, :multiple => true
      string :keywords, :multiple => true
      time :start
      time :end
      time :updated_at
=begin TODO: SOLR has a LatLonType to do geospatial searching. Have a look at that
      location :latitutde
      location :longitude
=end
    end
  end

  belongs_to :user

  has_many :package_events
  has_many :packages, through: :package_events

  belongs_to :content_provider

  validates :title, :url, presence: true

  serialize :field
  serialize :category
  serialize :keywords

  #Make sure there's url and title

  #Generated Event:
  # external_id:string
  # title:string
  # subtitle:string
  # url:string
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

  def self.facet_fields
    %w( category country field provider city sponsor keywords venue )
  end

end
