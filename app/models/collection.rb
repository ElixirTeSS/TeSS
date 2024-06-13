class Collection < ApplicationRecord
  include PublicActivity::Model
  include LogParameterChanges
  include Searchable
  include HasFriendlyId
  include CurationQueue
  include Collaboratable

  has_many :items, -> { order(:order) }, class_name: 'CollectionItem', inverse_of: :collection, dependent: :destroy
  has_many :material_items, -> { where(resource_type: 'Material').order(:order) }, class_name: 'CollectionItem',
           inverse_of: :collection
  has_many :event_items, -> { where(resource_type: 'Event').order(:order) }, class_name: 'CollectionItem',
           inverse_of: :collection
  has_many :events, through: :items, source: :resource, source_type: 'Event', inverse_of: :collections
  has_many :materials, through: :items, source: :resource, source_type: 'Material', inverse_of: :collections

  #has_one :owner, foreign_key: "id", class_name: "User"
  belongs_to :user

  # Remove trailing and squeezes (:squish option) white spaces inside the string (before_validation):
  # e.g. "James     Bond  " => "James Bond"
  auto_strip_attributes :title, :description, :image_url, squish: false

  accepts_nested_attributes_for :items, allow_destroy: true

  after_validation :normalize_order
  after_commit :index_items, if: :title_previously_changed?

  validates :title, presence: true

  clean_array_fields(:keywords)
  update_suggestions(:keywords)

  has_image(placeholder: TeSS::Config.placeholder['collection'])

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      text :title
      text :description
      text :keywords
      string :title
      string :sort_title do
        title.downcase.gsub(/^(an?|the) /, '')
      end
      string :user do
        self.user.username.to_s unless self.user.blank?
      end
      string :keywords, multiple: true
      string :user, multiple: true do
        [user.username, user.full_name].reject(&:blank?) if user
      end
      integer :collaborator_ids, multiple: true
      integer :user_id
      boolean :public
      time :created_at
      time :updated_at
    end
    # :nocov:
  end

  #Overwrites a collections materials and events.
  #[] or nil will delete
  def update_resources_by_id(materials=[], events=[])
    self.update_attribute('materials', materials.uniq.collect{|materials| Material.find_by_id(materials)}.compact) if materials
    self.update_attribute('events', events.uniq.collect{|events| Event.find_by_id(events)}.compact) if events
  end

  def self.facet_fields
    %w( keywords user )
  end

  def self.visible_by(user)
    if user&.is_admin?
      all
    elsif user
      references(:collaborations).includes(:collaborations).
        where("#{self.table_name}.public = :public OR #{self.table_name}.user_id = :user OR collaborations.user_id = :user",
              public: true, user: user)
    else
      where(public: true)
    end
  end

  # implement methods to allow processing as resource
  def content_provider
    nil
  end

  def scientific_topics
    []
  end

  private

  def index_items
    return unless TeSS::Config.solr_enabled

    items.each(&:reindex_resource)
  end

  # Make sure order for each type goes from 1 to n with no gaps.
  def normalize_order
    indexes = Hash.new(0)
    items.sort_by(&:order).each do |item|
      next if item.marked_for_destruction?
      item.order = indexes[item.resource_type] += 1
    end
  end
end
