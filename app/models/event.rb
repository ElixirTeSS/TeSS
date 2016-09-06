require 'icalendar'

class Event < ActiveRecord::Base
  include PublicActivity::Common
  has_paper_trail

  extend FriendlyId
  friendly_id :title, use: :slugged

  if SOLR_ENABLED
    searchable do
      text :title
      string :title
      text :url
      string :provider
      text :provider
      string :sponsor
      text :sponsor
      string :venue
      text :venue
      string :city
      text :city
      string :country
      text :country
      string :field, :multiple => true
      string :category, :multiple => true
      string :keywords, :multiple => true
      time :start
      time :end
      time :updated_at
      string :content_provider do
        if !self.content_provider.nil?
          self.content_provider.title
        end
      end
      text :content_provider do
        if !self.content_provider.nil?
          self.content_provider.title
        end
      end
      boolean :online
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

  has_many :external_resources, as: :source, dependent: :destroy

  accepts_nested_attributes_for :external_resources, allow_destroy: true

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

  def upcoming?
    # Handle nil for start date
    if self.start.blank?
      return true
    else
      return (Time.now < self.start)
    end
  end

  def started?
    if self.start and self.end
      return (Time.now > self.start and Time.now < self.end)
    else
      return false
    end
  end

  def expired?
    if self.end
      return Time.now > self.end
    else
      return false
    end
  end

  def self.facet_fields
    %w( category online country field provider city sponsor keywords venue content_provider )
  end

  def to_ical
    cal = Icalendar::Calendar.new

    cal.event do |ical_event|
      ical_event.dtstart     = Icalendar::Values::Date.new(self.start)
      ical_event.dtend       = Icalendar::Values::Date.new(self.end)
      ical_event.summary     = self.title
      ical_event.description = self.description
      ical_event.location    = self.venue unless self.venue.blank?
    end

    cal.to_ical
  end

end
