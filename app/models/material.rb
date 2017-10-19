require 'rails/html/sanitizer'

class Material < ActiveRecord::Base

  include PublicActivity::Common
  include HasScientificTopics
  include LogParameterChanges
  include HasAssociatedNodes
  include HasExternalResources
  include HasContentProvider
  include HasLicence
  include LockableFields
  include Scrapable
  include Searchable

  has_paper_trail

  extend FriendlyId
  friendly_id :title, use: :slugged

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      text :title
      string :title
      string :sort_title do
        title.downcase.gsub(/^(an?|the) /, '')
      end
      text :long_description
      text :short_description
      text :doi
      string :authors, :multiple => true
      text :authors
      string :scientific_topics, :multiple => true do
        self.scientific_topic_names
      end
      string :target_audience, :multiple => true
      text :target_audience
      string :keywords, :multiple => true
      text :keywords
      string :resource_type, :multiple => true
      text :resource_type
      string :difficulty_level do
        Tess::DifficultyDictionary.instance.lookup_value(self.difficulty_level, 'title')
      end
      text :difficulty_level
      string :contributors, :multiple => true
      text :contributors
      string :content_provider do
        self.content_provider.try(:title)
      end
      text :content_provider do
        self.content_provider.try(:title)
      end
      string :node, multiple: true do
        self.associated_nodes.map(&:name)
      end
      time :updated_at
      time :created_at
      time :last_scraped
      string :user do
        user.username if user
      end
    end
    # :nocov:
  end

  # has_one :owner, foreign_key: "id", class_name: "User"
  belongs_to :user
  has_one :edit_suggestion, as: :suggestible, dependent: :destroy
  has_many :package_materials
  has_many :packages, through: :package_materials
  has_many :event_materials, dependent: :destroy
  has_many :events, through: :event_materials

  # Remove trailing and squeezes (:squish option) white spaces inside the string (before_validation):
  # e.g. "James     Bond  " => "James Bond"
  auto_strip_attributes :title, :short_description, :long_description, :url, :squish => false

  validates :title, :short_description, :url, presence: true

  validates :url, url: true

  validates :difficulty_level, controlled_vocabulary: { dictionary: Tess::DifficultyDictionary.instance }

  clean_array_fields(:keywords, :contributors, :authors, :target_audience, :resource_type)

  update_suggestions(:keywords, :contributors, :authors, :target_audience, :resource_type)

  def short_description= desc
    super(Rails::Html::FullSanitizer.new.sanitize(desc))
  end

  def long_description= desc
    super(Rails::Html::FullSanitizer.new.sanitize(desc))
  end

  def self.facet_fields
    %w( scientific_topics tools standard_database_or_policy target_audience keywords difficulty_level
        authors related_resources contributors licence node content_provider user resource_type)
  end

  def self.check_exists(material_params)
    given_material = self.new(material_params)
    material = nil

    if given_material.url.present?
      material = self.find_by_url(given_material.url)
    end

    if given_material.content_provider.present? && given_material.title.present?
      material ||= self.where(content_provider_id: given_material.content_provider_id,
                                   title: given_material.title).last
    end

    material
  end
end
