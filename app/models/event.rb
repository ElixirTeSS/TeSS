require 'icalendar'
require 'rails/html/sanitizer'

class Event < ActiveRecord::Base
  include PublicActivity::Common
  include LogParameterChanges
  include HasAssociatedNodes
  include HasScientificTopics
  include HasExternalResources
  include HasContentProvider

  has_paper_trail
  before_save :set_default_times

  extend FriendlyId
  friendly_id :title, use: :slugged

  if TeSS::Config.solr_enabled
    searchable do
      text :title
      string :title
      string :sort_title do
        title.downcase.gsub(/^(an?|the) /, '')
      end
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
      string :target_audience, multiple: true
      boolean :online
      text :host_institutions
      time :last_scraped
      text :timezone
      string :user do
        if self.user
          self.user.username
        end
      end
=begin TODO: SOLR has a LatLonType to do geospatial searching. Have a look at that
      location :latitutde
      location :longitude
=end
    end
  end

  belongs_to :user
  has_many :package_events
  has_many :packages, through: :package_events
  has_many :event_materials
  has_many :materials, through: :event_materials

  validates :title, :url, presence: true
  validates :capacity, numericality: true, allow_blank: true
  validates :event_types, controlled_vocabulary: { dictionary: Tess::EventTypeDictionary.instance }
  validates :eligibility, controlled_vocabulary: { dictionary: Tess::EligibilityDictionary.instance }
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90, allow_nil: true }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180, allow_nil: true  }

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
    %w( event_types online country scientific_topics tools organizer city sponsor keywords venue content_provider
        node target_audience user )
  end

  def to_csv_event
      if self.organizer.class == String
        organizer = self.organizer.gsub(',',' ')
      elsif self.organizer.class == Array
        organizer = self.organizer.join(' | ').gsub(',',' and ')
      else
        organizer = nil
      end
      cp = self.content_provider.title unless self.content_provider.nil?

      [self.title.gsub(',',' '),
              organizer,
              self.start.strftime("%d %b %Y"),
              self.end.strftime("%d %b %Y"),
              cp]
  end

  def to_ical
    cal = Icalendar::Calendar.new
    cal.add_event(self.to_ical_event)
    cal.to_ical
  end

  def to_ical_event
    Icalendar::Event.new.tap do |ical_event|
      ical_event.dtstart     = Icalendar::Values::Date.new(self.start) unless self.start.blank?
      ical_event.dtend       = Icalendar::Values::Date.new(self.end) unless self.end.blank?
      ical_event.summary     = self.title
      ical_event.description = self.description
      ical_event.location    = self.venue unless self.venue.blank?
    end
  end

  def show_map?
    !(self.online? || self.latitude.blank? || self.longitude.blank?)
  end

  def all_day?
    self.start && self.end && (self.start == self.start.midnight) || (self.end == self.end.midnight)
  end

  # Ticket #375.
  # Default end at start +1 hour for online events.
  # Default end at 17:00 same day otherwise.
  # Default start time 9am.
  def set_default_times
    if !self.start
      return
    end

    if self.start.hour == 0 # hour set to 0 if not otherwise defined...
      self.start = self.start + 9.hours
    end

    if !self.end
      if self.online?
        self.end = self.start + 1.hour
      else
        diff = 17 - self.start.hour
        self.end = self.start + diff.hours
      end
    end
    # TODO: Set timezone for online events. Where to get it from, though?
    # TODO: Check events form to add timezone autocomplete.
    # Get timezones from: https://timezonedb.com/download

  end

  def self.not_finished
    where('events.end > ?', Time.now).where.not(end: nil)
  end

  def self.finished
    where('events.end < ?', Time.now).where.not(end: nil)
  end

end
