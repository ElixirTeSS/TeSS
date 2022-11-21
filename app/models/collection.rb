class Collection < ApplicationRecord
  include PublicActivity::Model
  include LogParameterChanges
  include Searchable
  include HasFriendlyId
  include CurationQueue
  include Collaboratable

  has_many :items, -> { order(:order) }, class_name: 'CollectionItem', inverse_of: :collection, dependent: :destroy
  has_many :events, through: :items, source: :resource, source_type: 'Event', inverse_of: :collections
  has_many :materials, through: :items, source: :resource, source_type: 'Material', inverse_of: :collections

  #has_one :owner, foreign_key: "id", class_name: "User"
  belongs_to :user

  # Remove trailing and squeezes (:squish option) white spaces inside the string (before_validation):
  # e.g. "James     Bond  " => "James Bond"
  auto_strip_attributes :title, :description, :image_url, :squish => false

  validates :title, presence: true

  clean_array_fields(:keywords)
  update_suggestions(:keywords)

  has_image(placeholder: TeSS::Config.placeholder['collection'])

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      text :title
      text :description
      string :title
      string :sort_title do
        title.downcase.gsub(/^(an?|the) /, '')
      end
      string :user do
        self.user.username.to_s unless self.user.blank?
      end
      string :keywords, :multiple => true

      string :user, :multiple => true do
        [user.username, user.full_name].reject(&:blank?) if user
      end

      integer :user_id
      boolean :public
      time :created_at
      time :updated_at
      integer :collaborator_ids, multiple: true
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
  def last_scraped
    nil
  end

  def content_provider
    nil
  end

  def scientific_topics
    []
  end
end
