class Material < ActiveRecord::Base

  include PublicActivity::Common
  has_paper_trail

  extend FriendlyId
  friendly_id :title, use: :slugged

  if SOLR_ENABLED==true
    searchable do
      text :title
      string :title
      text :long_description
      text :short_description
      text :doi
      string :authors, :multiple => true
      text :authors
      string :scientific_topics, :multiple => true do
        if !self.scientific_topics.nil?
          self.scientific_topics.map{|x| x.preferred_label}
        end
      end
      string :target_audience, :multiple => true
      text :target_audience
      string :keywords, :multiple => true
      text :keywords
      string :licence, :multiple => true
      text :licence
      string :difficulty_level, :multiple => true
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
      string :submitter, :multiple => true do
        submitter_index
      end
      text :submitter do
        submitter_index
      end
      time :updated_at
    end
  end

  # has_one :owner, foreign_key: "id", class_name: "User"
  belongs_to :user

  has_many :scientific_topics, foreign_key: 'class_id', class_name: "ScientificTopic"

  has_many :package_materials
  has_many :packages, through: :package_materials

  belongs_to :content_provider

  # Remove trailing and squeezes (:squish option) white spaces inside the string (before_validation):
  # e.g. "James     Bond  " => "James Bond"
  auto_strip_attributes :title, :short_description, :long_description, :url, :squish => false

  validates :title, :short_description, :url, presence: true

  # Validate the URL is in correct format via valid_url gem
  validates :url, :url => true

  clean_array_fields(:keywords, :contributors, :authors, :scientific_topics)

  update_suggestions(:keywords, :contributors, :authors)

  after_save :log_activities

  def log_activities
    self.changed.each do |changed_attribute|
      #TODO: Sort out what gets logged
      # If content provider - find content provider otherwise uses ID.
      #     maybe add new activity for content provider having a new material added to it too.
      # If updated at - ignore
      self.create_activity :update_parameter, parameters: {attr: changed_attribute, new_val: self.send(changed_attribute)}
    end
  end

  def self.owner
    self.user
  end

  def self.facet_fields
    %w(content_provider scientific_topics target_audience keywords licence difficulty_level authors contributors)
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

