class LearningPathTopic < ApplicationRecord
  include PublicActivity::Model
  include LogParameterChanges
  include Searchable
  include Collaboratable

  has_many :items, -> { order(:order) }, class_name: 'LearningPathTopicItem', inverse_of: :topic, foreign_key: :topic_id,
           dependent: :destroy
  has_many :material_items, -> { where(resource_type: 'Material').order(:order) }, class_name: 'LearningPathTopicItem',
           inverse_of: :topic, foreign_key: :topic_id
  has_many :event_items, -> { where(resource_type: 'Event').order(:order) }, class_name: 'LearningPathTopicItem',
           inverse_of: :topic, foreign_key: :topic_id
  has_many :events, through: :items, source: :resource, source_type: 'Event'
  has_many :materials, through: :items, source: :resource, source_type: 'Material'

  belongs_to :user

  auto_strip_attributes :title, :description, squish: false

  accepts_nested_attributes_for :items, allow_destroy: true

  after_validation :normalize_order

  validates :title, presence: true

  clean_array_fields(:keywords)
  update_suggestions(:keywords)

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
      integer :user_id
      time :created_at
      time :updated_at
    end
    # :nocov:
  end

  def self.facet_fields
    %w( keywords user )
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

  private

  # Make sure order for each type goes from 1 to n with no gaps.
  def normalize_order
    indexes = Hash.new(0)
    items.sort_by(&:order).each do |item|
      next if item.marked_for_destruction?
      item.order = indexes[item.resource_type] += 1
    end
  end
end
