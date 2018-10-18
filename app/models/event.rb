require 'icalendar'
require 'rails/html/sanitizer'
require 'redis'

class Event < ApplicationRecord
  include PublicActivity::Common
  include LogParameterChanges
  include HasAssociatedNodes
  include HasExternalResources
  include HasContentProvider
  include LockableFields
  include Scrapable
  include Searchable
  include CurationQueue
  include HasSuggestions
  include IdentifiersDotOrg
  include HasFriendlyId

  before_save :set_default_times, :check_country_name
  before_save :geocoding_cache_lookup, if: :address_will_change?
  after_save :enqueue_geocoding_worker, if: :address_changed?

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      text :title
      string :title
      string :sort_title do
        title.downcase.gsub(/^(an?|the) /, '')
      end
      text :url
      string :organizer
      text :organizer
      string :sponsors, :multiple => true
      string :venue
      text :venue
      string :city
      text :city
      string :country
      text :country
      string :event_types, :multiple => true do
        EventTypeDictionary.instance.values_for_search(self.event_types)
      end
      string :keywords, :multiple => true
      time :start
      time :end
      time :created_at
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
      string :operations, :multiple => true do
        self.operation_names
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
      integer :user_id # Used for shadowbans
      boolean :failing do
        failing?
      end
=begin TODO: SOLR has a LatLonType to do geospatial searching. Have a look at that
      location :latitutde
      location :longitude
=end
    end
    # :nocov:
  end

  belongs_to :user
  has_one :edit_suggestion, as: :suggestible, dependent: :destroy
  has_one :link_monitor, as: :lcheck, dependent: :destroy
  has_many :package_events
  has_many :packages, through: :package_events
  has_many :event_materials, dependent: :destroy
  has_many :materials, through: :event_materials
  has_many :widget_logs, as: :resource

  has_ontology_terms(:scientific_topics, branch: OBO_EDAM.topics)
  has_ontology_terms(:operations, branch: OBO_EDAM.operations)

  validates :title, :url, presence: true
  validates :capacity, numericality: true, allow_blank: true
  validates :event_types, controlled_vocabulary: { dictionary: EventTypeDictionary.instance }
  validates :eligibility, controlled_vocabulary: { dictionary: EligibilityDictionary.instance }
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90, allow_nil: true }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180, allow_nil: true  }
  validate :allowed_url

  clean_array_fields(:keywords, :event_types, :target_audience, :eligibility, :host_institutions, :sponsors)
  update_suggestions(:keywords, :target_audience, :host_institutions)

  # These fields should not been shown to users unless they have sufficient privileges
  SENSITIVE_FIELDS = [:funding, :attendee_count, :applicant_count, :trainer_count, :feedback, :notes]

  ADDRESS_FIELDS = [:venue, :city, :county, :country, :postcode]

  COUNTRY_SYNONYMS = JSON.parse(File.read(File.join(Rails.root, 'config', 'data', 'country_synonyms.json')))

  NOMINATIM_DELAY = 1.minute
  NOMINATIM_MAX_ATTEMPTS = 3

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

  def has_node?
    if self.content_provider
      if self.content_provider.node_id
        return true
      end
    end
    return false
  end

  def self.facet_fields
    %w( scientific_topics operations event_types online country tools organizer city sponsors target_audience keywords
        venue node content_provider user )
  end

  def to_csv_event
      if self.organizer.class == String
        organizer = self.organizer.tr(',',' ')
      elsif self.organizer.class == Array
        organizer = self.organizer.join(' | ').gsub(',',' and ')
      else
        organizer = nil
      end
      cp = self.content_provider.title unless self.content_provider.nil?

      [self.title.tr(',',' '),
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
    !self.online? &&
    ((self.latitude.present? && self.longitude.present?) ||
        (self.suggested_latitude.present? && self.suggested_longitude.present?))
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

  # Ticket #423
  def check_country_name
    if !self.country
      return
    end
    if self.country.respond_to?(:parameterize)
      text = self.country.parameterize.underscore.humanize.downcase
      if COUNTRY_SYNONYMS[text]
        self.country = COUNTRY_SYNONYMS[text]
      end
    end
  end

  def reported?
    SENSITIVE_FIELDS.any? { |f| self.send(f).present? }
  end

  def self.check_exists(event_params)
    given_event = self.new(event_params)
    event = nil

    if given_event.url.present?
      event = self.find_by_url(given_event.url)
    end

    if given_event.content_provider_id.present? && given_event.title.present? && given_event.start.present?
      event ||= self.where(content_provider_id: given_event.content_provider_id, title: given_event.title, start: given_event.start).last
    end

    event
  end

  def suggested_latitude
    if self.edit_suggestion && self.edit_suggestion.data_fields['geographic_coordinates']
      self.edit_suggestion.data_fields['geographic_coordinates'][0]
    end
  end

  def suggested_longitude
    if self.edit_suggestion && self.edit_suggestion.data_fields['geographic_coordinates']
      self.edit_suggestion.data_fields['geographic_coordinates'][1]
    end
  end

  def geographic_coordinates
    [self.latitude, self.longitude]
  end

  def geographic_coordinates=(coords)
    self.latitude = coords[0]
    self.longitude = coords[1]

    self.geographic_coordinates
  end

  def address
    ADDRESS_FIELDS.map { |field| self.send(field) }.reject(&:blank?).join(', ')
  end

  def address_will_change?
    ADDRESS_FIELDS.any? { |field| self.changes.keys.include?(field.to_s) }
  end

  def address_changed?
    ADDRESS_FIELDS.any? { |field| self.previous_changes.keys.include?(field.to_s) }
  end

  # Check the Redis cache for coordinates
  def geocoding_cache_lookup
    location = self.address

    begin
      redis = Redis.new
      if redis.exists(location)
        self.latitude, self.longitude = JSON.parse(redis.get(location))
        Rails.logger.info("Re-using: #{location}")
      end
    rescue Redis::RuntimeError => e
      raise e unless Rails.env.production?
      puts "Redis error: #{e.message}"
    end
  end

  # Check the external Geocoder API (currently Nominatim) for coordinates
  def geocoding_api_lookup
    location = self.address

    #result = Geocoder.search(location).first
    args = {postalcode: postcode, city: city, county: county, country: country, format: 'json'}
    result = nominatim_lookup(args)
    if result
      self.latitude = result[:lat]
      self.longitude = result[:lon]
      begin
        redis = Redis.new
        redis.set(location, [self.latitude, self.longitude].to_json)
      rescue Redis::RuntimeError => e
        raise e unless Rails.env.production?
        puts "Redis error: #{e.message}"
      end
    else
      self.update_column(:nominatim_count, self.nominatim_count + 1)
    end
  end

  # If no latitude or longitude, create a GeocodingWorker to find them.
  # This should run a minute after the last one is set to run (last run time stored by Redis).
  def enqueue_geocoding_worker
    return if (latitude.present? && longitude.present?) || (address.blank? && postcode.blank?) || nominatim_count >= NOMINATIM_MAX_ATTEMPTS

    location = address

    begin
      redis = Redis.new
      last_geocode = redis.get('last_geocode') || Time.now

      run_at = [last_geocode.to_i, Time.now.to_i].max + NOMINATIM_DELAY

      # submit event_id, and locations to worker.
      redis.set('last_geocode', run_at)
      GeocodingWorker.perform_at(run_at, [id, location])
    rescue Redis::RuntimeError => e
      raise e unless Rails.env.production?
      puts "Redis error: #{e.message}"
    end
  end

  def nominatim_lookup(args)
    url = 'https://nominatim.openstreetmap.org/search.php'
    response = HTTParty.get(url,
                            query: args,
                            headers: { 'User-Agent' => "Elixir TeSS <#{TeSS::Config.contact_email}>" })
    (JSON.parse response.body, symbolize_names: true)[0]
  end


  private

  def allowed_url
    disallowed = (TeSS::Config.blocked_domains || []).any? do |regex|
      url =~ regex
    end

    if disallowed
      errors.add(:url, 'not valid')
    end
  end

end
