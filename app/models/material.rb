require 'rails/html/sanitizer'

class Material < ActiveRecord::Base

  include PublicActivity::Common
  include HasScientificTopics
  include LogParameterChanges
  include HasAssociatedNodes
  include HasExternalResources
  include HasContentProvider

  has_paper_trail

  extend FriendlyId
  friendly_id :title, use: :slugged

  if SOLR_ENABLED
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
      string :licence do
        Tess::LicenceDictionary.instance.lookup_value(self.licence, 'title')
      end
      text :licence
      string :difficulty_level do
        Tess::DifficultyDictionary.instance.lookup_value(self.difficulty_level, 'title')
      end
      text :difficulty_level
      string :contributors, :multiple => true
      text :contributors
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
      string :submitter, :multiple => true do
        submitter_index
      end
      text :submitter do
        submitter_index
      end
      time :updated_at
      time :created_at
      time :last_scraped
      string :user do
        if self.user
          self.user.username
        end
      end
    end
  end

  # has_one :owner, foreign_key: "id", class_name: "User"
  belongs_to :user
  belongs_to :edit_suggestion
  has_many :package_materials
  has_many :packages, through: :package_materials

  # Remove trailing and squeezes (:squish option) white spaces inside the string (before_validation):
  # e.g. "James     Bond  " => "James Bond"
  auto_strip_attributes :title, :short_description, :long_description, :url, :squish => false

  validates :title, :short_description, :url, presence: true

  # Validate the URL is in correct format via valid_url gem
  validates :url, :url => true

  validates :difficulty_level, controlled_vocabulary: { dictionary: Tess::DifficultyDictionary.instance }
  validates :licence, controlled_vocabulary: { dictionary: Tess::LicenceDictionary.instance }

  clean_array_fields(:keywords, :contributors, :authors, :target_audience)

  update_suggestions(:keywords, :contributors, :authors, :target_audience)

  def short_description= desc
    super(Rails::Html::FullSanitizer.new.sanitize(desc))
  end

  def long_description= desc
    super(Rails::Html::FullSanitizer.new.sanitize(desc))
  end

  def self.owner
    self.user
  end

  def self.facet_fields
    %w( content_provider scientific_topics tools standard_database_or_policy target_audience keywords difficulty_level
        authors related_resources contributors licence node user )
  end

  private
  def submitter_index
    if user = User.find_by_id(self.user_id)
      if user.profile.firstname or user.profile.surname
        return "#{user.profile.firstname} #{user.profile.surname}"
      else
        return user.username
      end
    end
  end

end

