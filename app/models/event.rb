require 'icalendar'
require 'rails/html/sanitizer'

class Event < ActiveRecord::Base
  include PublicActivity::Common
  include LogParameterChanges
  include HasAssociatedNodes
  include HasScientificTopics

  has_paper_trail

  extend FriendlyId
  friendly_id :title, use: :slugged

  if SOLR_ENABLED
    searchable do
      text :title
      string :title
      text :url
      string :organizer
      text :organizer
      string :sponsor
      text :sponsor
      string :venue
      text :venue
      string :city
      text :city
      string :country
      text :country
      string :event_types, :multiple => true do
        Tess::EventTypeDictionary.instance.values_for_search(self.event_types)
      end
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
      string :node, multiple: true do
        self.associated_nodes.map(&:name)
      end
      string :scientific_topics, :multiple => true do
        self.scientific_topic_names
      end
      boolean :online
      text :host_institutions
      time :last_scraped
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
  validates :capacity, numericality: true, allow_blank: true
  validates :event_types, controlled_vocabulary: { dictionary: Tess::EventTypeDictionary.instance }
  validates :eligibility, controlled_vocabulary: { dictionary: Tess::EligibilityDictionary.instance }

  clean_array_fields(:keywords, :event_types, :target_audience, :eligibility, :host_institutions)
  update_suggestions(:keywords, :target_audience, :host_institutions)

  #Generated Event:
  # external_id:string
  # title:string
  # subtitle:string
  # url:string
  # organizer:string
  # description:text
  # event_types:text
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

  def description= desc
    super(Rails::Html::FullSanitizer.new.sanitize(desc))
  end

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
    %w( event_types online country scientific_topics organizer city sponsor keywords venue content_provider node )
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

  def show_map?
    !(self.online? || self.latitude.blank? || self.longitude.blank?)
  end

end
