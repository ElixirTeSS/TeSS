class Material < ActiveRecord::Base
  include PublicActivity::Common
  has_paper_trail

  extend FriendlyId
  friendly_id :title, use: :slugged


  unless SOLR_ENABLED==false
    searchable do
      text :title
      string :title
      text :long_description
      text :short_description
      text :doi
      string :authors, :multiple => true
      string :scientific_topic, :multiple => true do
        if !self.scientific_topic.nil?
          self.scientific_topic.map{|x| x.preferred_label}
        end
      end
      string :target_audience, :multiple => true
      string :keywords, :multiple => true
      string :licence, :multiple => true
      string :difficulty_level, :multiple => true
      string :contributors, :multiple => true
      string :content_provider do
        if !self.content_provider.nil?
          self.content_provider.title
        end
      end
      time :updated_at
    end
  end

  has_one :owner, foreign_key: "id", class_name: "User"

  has_many :scientific_topic, foreign_key: 'class_id', class_name: "ScientificTopic"

  has_many :package_materials
  has_many :packages, through: :package_materials

  belongs_to :content_provider
  # Remove trailing and squeezes (:squish option) white spaces inside the string (before_validation):
  # e.g. "James     Bond  " => "James Bond"
  auto_strip_attributes :title, :short_description, :url, :squish => false

  validates :title, :short_description, :url, presence: true

  # Validate the URL is in correct format via valid_url gem
  validates :url, :url => true

  before_save :remove_empty_array_items

  after_save :log_activities

  # Generated:
  # title:text url:string short_description:string doi:string  remote_updated_date:date remote_created_date:date
  # TODO:
=begin
  License
  Scientific topic
  Target audience
  Keywords
  Level
  Duration
  Rating: average score
  Rating: votes
  Rating: reviews
  # Separate models needed for Rating, License, Keywords &c.
=end

  @@array_fields = %w(keywords contributors authors)
  def remove_empty_array_items
    @@array_fields.each do |field|
      self.send(field).reject!{|x| x.empty?}
    end
  end


  def log_activities
    self.changed.each do |changed_attribute|
      #TODO: Sort out what gets logged
      # If content provider - find content provider otherwise uses ID.
      #     maybe add new activity for content provider having a new material added to it too.
      # If updated at - ignore
      self.create_activity :update_parameter, parameters: {attr: changed_attribute, new_val: self.send(changed_attribute)}
    end
  end
end

