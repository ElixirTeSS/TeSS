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
  include FuzzyDictionaryMatch
  include WithTimezone
  include HasEdamTerms

  before_validation :fix_keywords, on: :create, if: :scraper_record
  before_validation :presence_default
  before_save :check_country_name # :set_default_times
  before_save :geocoding_cache_lookup, if: :address_will_change?
  after_save :enqueue_geocoding_worker, if: :address_changed?

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      # full text search fields
      text :title
      text :keywords
      text :url
      text :organizer
      text :venue
      text :city
      text :country
      text :host_institutions
      text :timezone
      text :content_provider do
        content_provider.title unless content_provider.nil?
      end
      text :scientific_topics do
        scientific_topics_and_synonyms
      end
      text :operations do
        operations_and_synonyms
      end
      # sort title
      string :sort_title do
        title.downcase.gsub(/^(an?|the) /, '')
      end
      # other fields
      string :title
      string :organizer
      string :sponsors, multiple: true
      string :venue
      string :city
      string :country
      string :event_types, multiple: true do
        EventTypeDictionary.instance.values_for_search(event_types)
      end
      string :eligibility, multiple: true do
        EligibilityDictionary.instance.values_for_search(eligibility)
      end
      string :keywords, multiple: true
      string :fields, multiple: true
      time :start, trie: true
      time :end
      time :created_at, trie: true
      time :updated_at
      string :content_provider do
        content_provider.title unless content_provider.nil?
      end
      string :node, multiple: true do
        associated_nodes.pluck(:name)
      end
      string :scientific_topics, multiple: true do
        scientific_topics_and_synonyms
      end
      string :operations, multiple: true do
        operations_and_synonyms
      end
      string :target_audience, multiple: true
      boolean :online do
        online? || hybrid?
      end
      time :last_scraped
      string :user do
        user.username if user
      end
      integer :user_id # Used for shadowbans
      boolean :failing do
        failing?
      end
      string :cost_basis
      # TODO: SOLR has a LatLonType to do geospatial searching. Have a look at that
      #       location :latitutde
      #       location :longitude
      string :collections, multiple: true do
        collections.where(public: true).pluck(:title)
      end
    end
    # :nocov:
  end

  enum presence: { onsite: 0, online: 1, hybrid: 2 }

  belongs_to :user
  has_one :edit_suggestion, as: :suggestible, dependent: :destroy
  has_one :link_monitor, as: :lcheck, dependent: :destroy
  has_many :collection_items, as: :resource
  has_many :collections, through: :collection_items
  has_many :event_materials, dependent: :destroy
  has_many :materials, through: :event_materials
  has_many :widget_logs, as: :resource

  has_ontology_terms(:scientific_topics, branch: OBO_EDAM.topics)
  has_ontology_terms(:operations, branch: OBO_EDAM.operations)

  has_many :stars,  as: :resource, dependent: :destroy

  auto_strip_attributes :title, :description, :url, squish: false

  validates :title, :url, presence: true
  validates :url, url: true
  validates :capacity, numericality: { greater_than_or_equal_to: 1 }, allow_blank: true
  validates :cost_value, numericality: { greater_than: 0 }, allow_blank: true
  validates :event_types, controlled_vocabulary: { dictionary: 'EventTypeDictionary' }
  validates :eligibility, controlled_vocabulary: { dictionary: 'EligibilityDictionary' }
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90, allow_nil: true }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180, allow_nil: true }
  # validates :duration, format: { with: /\A[0-9][0-9]:[0-5][0-9]\z/, message: "must be in format HH:MM" }, allow_blank: true
  validates :presence, inclusion: { in: presences.keys, allow_blank: true }
  validate :allowed_url
  clean_array_fields(:keywords, :fields, :event_types, :target_audience,
                     :eligibility, :host_institutions, :sponsors)
  update_suggestions(:keywords, :target_audience, :host_institutions)
  fuzzy_dictionary_match(event_types: 'EventTypeDictionary',
                         eligibility: 'EligibilityDictionary')

  # These fields should not been shown to users unless they have sufficient privileges
  SENSITIVE_FIELDS = %i[funding attendee_count applicant_count trainer_count feedback notes]

  ADDRESS_FIELDS = %i[venue city county country postcode]

  COUNTRY_SYNONYMS = JSON.parse(File.read(File.join(Rails.root, 'config', 'data', 'country_synonyms.json')))

  NOMINATIM_DELAY = 1.minute
  NOMINATIM_MAX_ATTEMPTS = 3

  def description=(desc)
    super(Rails::Html::FullSanitizer.new.sanitize(desc))
  end

  def start_utc
    convert_local_to_utc start
  end

  def end_utc
    convert_local_to_utc self.end
  end

  def start_local
    set_to_local start
  end

  def end_local
    set_to_local self.end
  end

  def started?
    if start and self.end
      (Time.now > start and Time.now < self.end)
    else
      false
    end
  end

  def expired?
    if self.end
      Time.now > self.end
    else
      false
    end
  end

  def self.facet_fields
    field_list = %w[ content_provider keywords scientific_topics operations tools fields online event_types
                     start venue city country organizer sponsors target_audience eligibility user node collections ]

    field_list.delete('operations') if TeSS::Config.feature['disabled'].include? 'operations'
    field_list.delete('scientific_topics') if TeSS::Config.feature['disabled'].include? 'topics'
    field_list.delete('sponsors') if TeSS::Config.feature['disabled'].include? 'sponsors'
    field_list.delete('tools') if TeSS::Config.feature['disabled'].include? 'biotools'
    field_list.delete('fields') if TeSS::Config.feature['disabled'].include? 'ardc_fields_of_research'
    field_list.delete('node') unless TeSS::Config.feature['nodes']
    field_list.delete('collections') unless TeSS::Config.feature['collections']

    field_list
  end

  def to_csv_event
    organizer = if self.organizer.instance_of?(String)
                  self.organizer.tr(',', ' ')
                elsif self.organizer.instance_of?(Array)
                  self.organizer.join(' | ').gsub(',', ' and ')
                end
    cp = content_provider.title unless content_provider.nil?

    [title.tr(',', ' '),
     organizer,
     start.strftime('%d %b %Y'),
     self.end.strftime('%d %b %Y'),
     cp]
  end

  def to_ical
    cal = Icalendar::Calendar.new
    cal.add_event(to_ical_event)
    cal.to_ical
  end

  def to_ical_event
    Icalendar::Event.new.tap do |ical_event|
      if start && self.end
        if all_day?
          ical_event.dtstart = Icalendar::Values::Date.new(start, tzid: 'UTC') unless start.blank?
          ical_event.dtend = Icalendar::Values::Date.new(self.end.tomorrow, tzid: 'UTC') unless self.end.blank?
        else
          ical_event.dtstart = Icalendar::Values::DateTime.new(start_utc, tzid: 'UTC') unless start.blank?
          ical_event.dtend = Icalendar::Values::DateTime.new(end_utc, tzid: 'UTC') unless self.end.blank?
        end

      end
      ical_event.summary = title
      ical_event.description = description
      ical_event.location = venue unless venue.blank?
      ical_event.url = url
    end
  end

  def show_map?
    TeSS::Config.map_enabled && ((latitude.present? && longitude.present?) || (suggested_latitude.present? && suggested_longitude.present?))
  end

  def all_day?
    start && self.end &&
      (start == start.midnight) &&
      (self.end.hour == 23) && (self.end.min == 59)
  end

  # Ticket #375.
  # Default end at start +1 hour for online events.
  # Default end at 17:00 same day otherwise.
  # Default start time 9am.
  def set_default_times
    return unless start

    self.start = start + 9.hours if start.hour == 0 # hour set to 0 if not otherwise defined...

    unless self.end
      if online?
        self.end = start + 1.hour
      else
        diff = 17 - start.hour
        self.end = start + diff.hours
      end
    end
    # TODO: Set timezone for online events. Where to get it from, though?
    # TODO: Check events form to add timezone autocomplete.
    # Get timezones from: https://timezonedb.com/download
  end

  def self.not_finished
    where('events.end > ? OR events.end IS NULL', Time.now)
  end

  def self.finished
    where('events.end < ?', Time.now).where.not(end: nil)
  end

  # Ticket #423
  def check_country_name
    if country and country.respond_to?(:parameterize)
      text = country.parameterize.underscore.humanize.downcase
      self.country = COUNTRY_SYNONYMS[text] if COUNTRY_SYNONYMS[text]
    end
    true
  end

  def reported?
    SENSITIVE_FIELDS.any? { |f| send(f).present? }
  end

  def self.check_exists(event_params)
    given_event = event_params.is_a?(Event) ? event_params : new(event_params)
    event = nil

    provider_id = (given_event.content_provider_id || given_event.content_provider&.id)&.to_s

    scope = provider_id.present? ? where(content_provider_id: provider_id) : all

    if given_event.url.present?
      event = scope.where(url: given_event.url).last
    end

    if given_event.title.present? && given_event.start.present?
      event ||= where(content_provider_id: provider_id, title: given_event.title, start: given_event.start).last
    end

    event
  end

  def suggested_latitude
    edit_suggestion.data_fields['geographic_coordinates'][0] if edit_suggestion && edit_suggestion.data_fields['geographic_coordinates']
  end

  def suggested_longitude
    edit_suggestion.data_fields['geographic_coordinates'][1] if edit_suggestion && edit_suggestion.data_fields['geographic_coordinates']
  end

  def geographic_coordinates
    [latitude, longitude]
  end

  def geographic_coordinates=(coords)
    self.latitude = coords[0]
    self.longitude = coords[1]

    geographic_coordinates
  end

  def address
    ADDRESS_FIELDS.map { |field| send(field) }.reject(&:blank?).join(', ')
  end

  def address_will_change?
    ADDRESS_FIELDS.any? { |field| changes.keys.include?(field.to_s) }
  end

  def address_changed?
    ADDRESS_FIELDS.any? { |field| previous_changes.keys.include?(field.to_s) }
  end

  # Check the Redis cache for coordinates
  def geocoding_cache_lookup
    location = address

    begin
      redis = Redis.new(url: TeSS::Config.redis_url)
      if redis.exists?(location)
        self.latitude, self.longitude = JSON.parse(redis.get(location))
        Rails.logger.info("Re-using: #{location}")
      end
    rescue Redis::BaseError => e
      raise e unless Rails.env.production?

      puts "Redis error: #{e.message}"
    end

    # return true to enable error messages
    true
  end

  # Check the external Geocoder API (currently Nominatim) for coordinates
  def geocoding_api_lookup
    location = address

    # result = Geocoder.search(location).first
    args = { postalcode: postcode, city: city, county: county, country: country, format: 'json' }
    result = nominatim_lookup(args)
    if result
      self.latitude = result[:lat]
      self.longitude = result[:lon]
      begin
        redis = Redis.new(url: TeSS::Config.redis_url)
        redis.set(location, [latitude, longitude].to_json)
      rescue Redis::BaseError => e
        raise e unless Rails.env.production?

        puts "Redis error: #{e.message}"
      end
    else
      update_column(:nominatim_count, nominatim_count + 1)
    end
  end

  # If no latitude or longitude, create a GeocodingWorker to find them.
  # This should run a minute after the last one is set to run (last run time stored by Redis).
  def enqueue_geocoding_worker
    return unless TeSS::Config.feature['geocoding']
    return if (latitude.present? && longitude.present?) ||
              (address.blank? && postcode.blank?) ||
              nominatim_count >= NOMINATIM_MAX_ATTEMPTS

    location = address

    begin
      redis = Redis.new(url: TeSS::Config.redis_url)
      last_geocode = redis.get('last_geocode') || Time.now

      run_at = [last_geocode.to_i, Time.now.to_i].max + NOMINATIM_DELAY

      # submit event_id, and locations to worker.
      redis.set('last_geocode', run_at)
      GeocodingWorker.perform_at(run_at, [id, location])
    rescue Redis::BaseError => e
      raise e unless Rails.env.production?

      puts "Redis error: #{e.message}"
    end
  end

  def nominatim_lookup(args)
    url = 'https://nominatim.openstreetmap.org/search.php'
    response = HTTParty.get(url,
                            query: args,
                            headers: { 'User-Agent' => "ELIXIR TeSS <#{TeSS::Config.contact_email}>" })
    (JSON.parse response.body, symbolize_names: true)[0]
  end

  def to_bioschemas
    if event_types.include?('workshops_and_courses')
      [Bioschemas::CourseGenerator.new(self)]
    else
      [Bioschemas::EventGenerator.new(self)]
    end
  end

  def duplicate
    c = dup
    c.url = nil
    external_resources.each do |er|
      c.external_resources.build(url: er.url, title: er.title)
    end
    [:materials, :scientific_topics, :operations, :nodes].each do |field|
      c.send("#{field}=", send(field))
    end

    c
  end

  def online= value
    value = :online if value.is_a?(TrueClass) || value == '1' || value == 1 || value == 'true'
    value = :onsite if value.is_a?(FalseClass) || value == '0' || value == 0 || value == 'false'
    self.presence = value
  end

  private

  def allowed_url
    disallowed = (TeSS::Config.blocked_domains || []).any? do |regex|
      url =~ regex
    end

    errors.add(:url, 'not valid') if disallowed
  end

  def convert_local_to_utc(datetime)
    set_to_local(datetime).in_time_zone('UTC')
  rescue StandardError
    datetime
  end

  def set_to_local(datetime)
    datetime.asctime.in_time_zone(timezone)
  rescue StandardError
    datetime
  end

  def fix_online
    dic = OnlineKeywordsDictionary.instance
    dic.keys.each do |key|
      downcased_var = self[key]&.downcase
      dic.lookup(key).each do |v|
        if downcased_var&.include?(v)
          self.presence = :online
          return
        end
      end
    end
  end

  def fix_keywords
    fix_online unless online? || hybrid?

    [
      [TargetAudienceDictionary, :target_audience],
      [EventTypeDictionary, :event_types],
      [EligibilityDictionary, :eligibility],
    ].each do |dict, var|
      if self[var].blank?
        self[var] = []
      end
      dic = dict.instance
      self&.keywords&.dup&.each do |kw|
        res = dic.best_match(kw)
        if res
          self[var].append(kw)
          self.keywords.delete(kw)
        end
      end
    end
  end

  def presence_default
    self.presence = :onsite if presence.blank?
  end
end
