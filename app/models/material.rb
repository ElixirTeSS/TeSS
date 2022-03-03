require 'rails/html/sanitizer'

class Material < ApplicationRecord
  include PublicActivity::Common
  include LogParameterChanges
  include HasAssociatedNodes
  include HasExternalResources
  include HasContentProvider
  include HasLicence
  include LockableFields
  include Scrapable
  include Searchable
  include CurationQueue
  include HasSuggestions
  include IdentifiersDotOrg
  include HasFriendlyId

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      # full text search fields
      text :title
      text :description
      text :contact
      text :doi
      text :authors
      text :contributors
      text :target_audience
      text :keywords
      text :resource_type
      text :content_provider do
        self.content_provider.try(:title)
      end
      # sort title
      string :sort_title do
        title.downcase.gsub(/^(an?|the) /, '')
      end
      # other fields
      string :title
      string :authors, :multiple => true
      string :scientific_topics, :multiple => true do
        self.scientific_topic_names
      end
      string :operations, :multiple => true do
        self.operation_names
      end
      string :target_audience, :multiple => true
      string :keywords, :multiple => true
      string :fields, :multiple => true
      string :resource_type, :multiple => true
      string :difficulty_level do
        DifficultyDictionary.instance.lookup_value(self.difficulty_level, 'title')
      end
      string :contributors, :multiple => true
      string :content_provider do
        self.content_provider.try(:title)
      end
      string :node, multiple: true do
        self.associated_nodes.map(&:name)
      end
      time :updated_at
      time :created_at
      time :last_scraped
      boolean :failing do
        failing?
      end
      string :user do
        user.username if user
      end
      integer :user_id # Used for shadowbans
    end
    # :nocov:
  end

  # has_one :owner, foreign_key: "id", class_name: "User"
  belongs_to :user
  has_one :link_monitor, as: :lcheck, dependent: :destroy
  has_many :package_materials
  has_many :packages, through: :package_materials
  has_many :event_materials, dependent: :destroy
  has_many :events, through: :event_materials

  has_ontology_terms(:scientific_topics, branch: OBO_EDAM.topics)
  has_ontology_terms(:operations, branch: OBO_EDAM.operations)

  # Remove trailing and squeezes (:squish option) white spaces inside the string (before_validation):
  # e.g. "James     Bond  " => "James Bond"
  auto_strip_attributes :title, :description, :url, :squish => false

  validates :title, :description, :keywords, :url, :licence, :status, :contact, presence: true

  validates :url, url: true

  validates :licence, exclusion: { in: ['notspecified'], message: 'must be specified' }

  validates :other_types, presence: true, if: Proc.new { |m| m.resource_type.include?('other') }

  validates :difficulty_level, controlled_vocabulary: { dictionary: DifficultyDictionary.instance }

  clean_array_fields(:keywords, :fields, :contributors, :authors,
                     :target_audience, :resource_type, :subsets)

  update_suggestions(:keywords, :contributors, :authors, :target_audience,
                     :resource_type)

  def description= desc
    super(Rails::Html::FullSanitizer.new.sanitize(desc))
  end

  def self.facet_fields
    field_list = %w( content_provider keywords fields licence target_audience
                     authors contributors resource_type related_resources
                     user )
    field_list.append('operations') unless TeSS::Config.feature['disabled'].include? 'operations'
    field_list.append('scientific_topics') unless TeSS::Config.feature['disabled'].include? 'topics'
    field_list.append('standard_database_or_policy') unless TeSS::Config.feature['disabled'].include? 'fairshare'
    field_list.append('tools') unless TeSS::Config.feature['disabled'].include? 'biotools'
    field_list.append('node') if TeSS::Config.feature['nodes']
    return field_list
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
