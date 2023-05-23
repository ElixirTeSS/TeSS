# frozen_string_literal: true

class ContentProvider < ApplicationRecord
  # The order of these determines which providers have precedence when scraping.
  # Low -> High
  PROVIDER_TYPE = ['Portal', 'Organisation', 'Project'].freeze

  include PublicActivity::Common
  include LogParameterChanges
  include Searchable
  include IdentifiersDotOrg
  include HasFriendlyId
  include CurationQueue

  has_many :materials, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :sources, dependent: :destroy

  belongs_to :user
  belongs_to :node, optional: true

  has_and_belongs_to_many :editors, class_name: 'User'

  attribute :approved_editors, :string, array: true
  attribute :contact, :string

  # has_many :content_provider_users
  # has_many :editors, through: :users, source: :user, inverse_of: :providers

  delegate :name, to: :node, prefix: true, allow_nil: true

  # Remove trailing and squeezes (:squish option) white spaces inside the string (before_validation):
  # e.g. "James     Bond  " => "James Bond"
  auto_strip_attributes :title, :description, :url, :image_url, squish: false

  validates :title, :url, presence: true

  # Validate the URL is in correct format via valid_url gem
  validates :url, url: true

  validates :content_provider_type, presence: true, inclusion: { in: PROVIDER_TYPE }

  clean_array_fields(:keywords, :approved_editors)

  has_image(placeholder: TeSS::Config.placeholder['content_provider'])

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      # full text fields
      text :title
      text :description
      text :keywords
      # sort title
      string :sort_title do
        title.downcase.gsub(/^(an?|the) /, '')
      end
      # other fields
      string :title
      string :keywords, multiple: true
      string :node, multiple: true do
        node.name if node.present?
      end
      string :content_provider_type
      integer :count do
        if events.count > materials.count
          events.count
        else
          materials.count
        end
      end
      integer :user_id # Used for shadowbans
      time :created_at
      time :updated_at
    end
    # :nocov:
  end

  # TODO: Add validations for these:
  # title:text url:text image_url:text description:text

  def self.facet_fields
    %w[keywords node content_provider_type]
  end

  def node_name=(name)
    self.node = Node.find_by(name: name)
  end

  def precedence
    PROVIDER_TYPE.index(content_provider_type) || 0
  end

  def self.check_exists(content_provider_params)
    given_content_provider = new(content_provider_params)
    content_provider = nil

    content_provider = find_by(url: given_content_provider.url) if given_content_provider.url.present?

    content_provider ||= where(title: given_content_provider.title).last if given_content_provider.title.present?

    content_provider
  end

  def self.identifiers_dot_org_key
    'p'
  end

  def add_editor(editor)
    if !editor.nil? && !editors.include?(editor) && !user.nil? && (user.id != editor.id)
      editors << editor
      save!
      editor.editables.reload
    end
  end

  def remove_editor(editor)
    if !editor.nil? && editors.include?(editor)
      # remove from array
      editors.delete(editor)
      save!
      editor.editables.reload

      # transfer events to the provider's user
      editor.events.where(content_provider_id: id).find_each do |event|
        event.user = user
        event.save!
      end

      # transfer materials to the provider's user
      editor.materials.where(content_provider_id: id).find_each do |material|
        material.user = user
        material.save!
      end
      editor.reload
      editor.save!
    end
  end

  def approved_editors
    result = []
    editors.each { |editor| result << editor.username }
    # puts "get approved_editors: found #{result.size} editors"
    result
  end

  def approved_editors=(values)
    # puts "set approved_editors: user count #{values.size}"
    editors_list = []
    values.each do |item|
      if !item.nil? && item.present?
        list_user = User.find_by(username: item)
        editors_list << list_user unless list_user.nil?
      end
    end
    # add missing
    editors_list.each { |item| add_editor(item) unless editors.include?(item) }
    # remove old
    editors.each { |item| remove_editor(item) unless editors_list.include?(item) }
  end
end
