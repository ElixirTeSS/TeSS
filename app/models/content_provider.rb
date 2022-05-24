class ContentProvider < ApplicationRecord

  include PublicActivity::Common
  include LogParameterChanges
  include Searchable
  include IdentifiersDotOrg
  include HasFriendlyId
  include CurationQueue

  has_many :materials, :dependent => :destroy
  has_many :events, :dependent => :destroy
  has_many :sources, :dependent => :destroy

  belongs_to :user
  belongs_to :node, optional: true

  has_and_belongs_to_many :editors, class_name: "User"

  attribute :approved_editors, :string, array: true
  attribute :contact, :string

  #has_many :content_provider_users
  #has_many :editors, through: :users, source: :user, inverse_of: :providers

  delegate :name, to: :node, prefix: true, allow_nil: true

  # Remove trailing and squeezes (:squish option) white spaces inside the string (before_validation):
  # e.g. "James     Bond  " => "James Bond"
  auto_strip_attributes :title, :description, :url, :image_url, :squish => false

  validates :title, :url, presence: true

  # Validate the URL is in correct format via valid_url gem
  validates :url, url: true

  clean_array_fields(:keywords, :approved_editors)

  # The order of these determines which providers have precedence when scraping.
  # Low -> High
  PROVIDER_TYPE = ['Portal', 'Organisation', 'Project']
  has_image(placeholder: TeSS::Config.placeholder['provider'])

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
      string :keywords, :multiple => true
      string :node, :multiple => true do
        unless self.node.blank?
          self.node.name
        end
      end
      string :content_provider_type
      integer :count do
        if self.events.count > self.materials.count
          self.events.count
        else
          self.materials.count
        end
      end
      integer :user_id # Used for shadowbans
      time :updated_at
    end
    # :nocov:
  end

  # TODO: Add validations for these:
  # title:text url:text image_url:text description:text

  def self.facet_fields
    %w( keywords node content_provider_type)
  end

  def node_name= name
    self.node = Node.find_by_name(name)
  end

  def precedence
    PROVIDER_TYPE.index(content_provider_type)
  end

  def self.check_exists(content_provider_params)
    given_content_provider = self.new(content_provider_params)
    content_provider = nil

    if given_content_provider.url.present?
      content_provider = self.find_by_url(given_content_provider.url)
    end

    if given_content_provider.title.present?
      content_provider ||= self.where(title: given_content_provider.title).last
    end

    content_provider
  end

  def self.identifiers_dot_org_key
    'p'
  end

  def add_editor(editor)
    if !editor.nil? and !editors.include?(editor) and !user.nil? and user.id != editor.id
      editors << editor
      save!
      editor.editables.reload
    end
  end

  def remove_editor(editor)
    if !editor.nil? and editors.include?(editor)
      # remove from array
      editors.delete(editor)
      save!
      editor.editables.reload

      # transfer events to the provider's user
      editor.events.each do |event|
        if event.content_provider.id == id
          event.user = user
          event.save!
        end
      end

      # transfer materials to the provider's user
      editor.materials.each do |material|
        if material.content_provider.id == id
          material.user = user
          material.save!
        end
      end
      editor.reload
      editor.save!
    end

  end

  def approved_editors
    result = []
    editors.each { |editor| result << editor.username }
    #puts "get approved_editors: found #{result.size} editors"
    return result
  end

  def approved_editors= values
    #puts "set approved_editors: user count #{values.size}"
    editors_list = []
    values.each do |item|
      if !item.nil? and !item.blank?
        list_user = User.find_by_username(item)
        editors_list << list_user if !list_user.nil?
      end
    end
    # add missing
    editors_list.each { |item| add_editor(item) if !editors.include?(item) }
    # remove old
    editors.each { |item| remove_editor(item) if !editors_list.include?(item) }
  end

end
