require 'rails/html/sanitizer'
require 'json/ld'
require 'rdf'
require 'rdf/rdfxml'
require 'builder'

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
  include HasDifficultyLevel
  include HasTermsAndSynonyms
  include InSpace
  include HasPeople

  APPROVAL_STATUS = {
    0 => :not_approved,
    1 => :requested,
    2 => :approved
  }.freeze

  APPROVAL_STATUS_CODES = APPROVAL_STATUS.invert.freeze

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      # full text search fields
      text :title
      text :description
      text :contact
      text :doi
      text :authors do
        authors.map(&:display_name)
      end
      text :contributors do
        contributors.map(&:display_name)
      end
      text :target_audience
      text :keywords
      text :resource_type
      boolean :visible
      text :content_provider do
        content_provider.try(:title)
      end
      text :scientific_topics do
        scientific_topics_and_synonyms
      end
      text :operations do
        operations_and_synonyms
      end
      # sort title
      string :sort_title do
        title.downcase.gsub(/^(an?|the) /, '')
      end
      # other fields
      string :title
      string :authors, multiple: true do
        authors.map(&:display_name)
      end
      string :scientific_topics, multiple: true do
        scientific_topics_and_synonyms
      end
      string :operations, multiple: true do
        operations_and_synonyms
      end
      string :target_audience, multiple: true
      string :keywords, multiple: true
      string :fields, multiple: true
      string :resource_type, multiple: true
      string :contributors, multiple: true do
        contributors.map(&:display_name)
      end
      string :content_provider do
        content_provider.try(:title)
      end
      string :node, multiple: true do
        associated_nodes.pluck(:name)
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
      string :collections, multiple: true do
        collections.where(public: true).pluck(:title)
      end
      string :status do
        MaterialStatusDictionary.instance.lookup_value(status, 'title')
      end
      string :approval_status do
        I18n.t("materials.approval_status.#{approval_status}")
      end
    end
    # :nocov:
  end

  # has_one :owner, foreign_key: "id", class_name: "User"
  belongs_to :user
  has_one :link_monitor, as: :lcheck, dependent: :destroy
  has_many :collection_items, as: :resource
  has_many :collections, through: :collection_items
  has_many :event_materials, dependent: :destroy
  has_many :events, through: :event_materials

  has_ontology_terms(:scientific_topics, branch: EDAM.topics)
  has_ontology_terms(:operations, branch: EDAM.operations)

  has_many :stars, as: :resource, dependent: :destroy

  # Use HasPeople concern for authors and contributors
  has_person_role :authors
  has_person_role :contributors

  # Remove trailing and squeezes (:squish option) white spaces inside the string (before_validation):
  # e.g. "James     Bond  " => "James Bond"
  auto_strip_attributes :title, :description, :url, squish: false

  validates :title, :description, :url, presence: true
  validates :url, url: true
  validates :other_types, presence: true, if: proc { |m| m.resource_type.include?('other') }
  validates :keywords, length: { maximum: 20 }
  validates :origin_uri, url: { allow_blank: true }

  validates :approval_status, inclusion: { in: APPROVAL_STATUS.values }
  before_create :set_approval_status
  before_update :log_approval_status_change
  before_update :reset_approval_status

  clean_array_fields(:keywords, :fields,
                     :target_audience, :resource_type, :subsets)

  update_suggestions(:keywords, :target_audience,
                     :resource_type)

  def description=(desc)
    super(Rails::Html::FullSanitizer.new.sanitize(desc))
  end

  def short_description=(desc)
    self.description = desc unless @_long_description_set
  end

  def long_description=(desc)
    @_long_description_set = true
    self.description = desc
  end

  def self.facet_fields
    field_list = %w[scientific_topics operations tools standard_database_or_policy content_provider keywords
                    difficulty_level fields licence target_audience authors contributors resource_type
                    related_resources user node collections status approval_status]

    field_list.delete('operations') if TeSS::Config.feature['disabled'].include? 'operations'
    field_list.delete('scientific_topics') if TeSS::Config.feature['disabled'].include? 'topics'
    field_list.delete('standard_database_or_policy') if TeSS::Config.feature['disabled'].include? 'fairshare'
    field_list.delete('tools') if TeSS::Config.feature['disabled'].include? 'biotools'
    field_list.delete('fields') if TeSS::Config.feature['disabled'].include? 'ardc_fields_of_research'
    field_list.delete('node') unless Space.current_space.feature_enabled?('nodes')
    field_list.delete('collections') unless Space.current_space.feature_enabled?('collections')
    field_list.delete('status') if TeSS::Config.feature['disabled'].include? 'status'

    field_list
  end

  def self.not_disabled
    where(visible: true)
  end

  def self.disabled
    where(visible: false)
  end

  def self.check_exists(material_params)
    given_material = material_params.is_a?(Material) ? material_params : new(material_params)
    material = nil

    provider_id = (given_material.content_provider_id || given_material.content_provider&.id)&.to_s

    scope = provider_id.present? ? where(content_provider_id: provider_id) : all

    material = scope.where(url: given_material.url).last if given_material.url.present?

    material ||= scope.where(content_provider_id: provider_id, title: given_material.title).last if provider_id.present? && given_material.title.present?

    material
  end

  def to_bioschemas
    [Bioschemas::LearningResourceGenerator.new(self)]
  end

  def duplicate
    c = dup
    c.url = nil
    external_resources.each do |er|
      c.external_resources.build(url: er.url, title: er.title)
    end
    %i[events scientific_topics operations nodes].each do |field|
      c.send("#{field}=", send(field))
    end

    c
  end

  def archived?
    status == 'archived'
  end

  def to_rdf
    jsonld_str = to_bioschemas[0].to_json

    graph = RDF::Graph.new
    JSON::LD::Reader.new(jsonld_str) do |reader|
      reader.each_statement { |stmt| graph << stmt }
    end

    rdfxml_str = graph.dump(:rdfxml, prefixes: { sdo: 'http://schema.org/', dc: 'http://purl.org/dc/terms/' })
    rdfxml_str.sub(/\A<\?xml.*?\?>\s*/, '') # remove XML declaration because this is used inside OAI-PMH response
  end

  def to_oai_dc
    xml = ::Builder::XmlMarkup.new
    xml.tag!('oai_dc:dc',
             'xmlns:oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/',
             'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
             'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
             'xsi:schemaLocation' => 'http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd') do
      xml.tag!('dc:title', title)
      xml.tag!('dc:description', description)
      authors.each { |a| xml.tag!('dc:creator', a.display_name) }
      contributors.each { |c| xml.tag!('dc:contributor', c.display_name) }
      xml.tag!('dc:publisher', content_provider.title) if content_provider

      xml.tag!('dc:format', 'text/html')
      xml.tag!('dc:language', 'en')
      xml.tag!('dc:rights', licence) if licence.present?

      [date_published, date_created, date_modified].compact.each do |d|
        xml.tag!('dc:date', d.iso8601)
      end

      if doi.present?
        doi_iri = doi.start_with?('http://', 'https://') ? doi : "https://doi.org/#{doi}"
        xml.tag!('dc:identifier', doi_iri)
      else
        xml.tag!('dc:identifier', url)
      end

      (keywords + scientific_topics.map(&:uri) + operations.map(&:uri)).each do |s|
        xml.tag!('dc:subject', s)
      end

      xml.tag!('dc:type', 'http://purl.org/dc/dcmitype/Text')
      xml.tag!('dc:type', 'https://schema.org/LearningResource')
      resource_type.each { |t| xml.tag!('dc:type', t) }

      xml.tag!('dc:relation', "#{TeSS::Config.base_url}#{Rails.application.routes.url_helpers.material_path(self)}")
      xml.tag!('dc:relation', content_provider.url) if content_provider&.url
    end
    xml.target!
  end

  def self.approved
    where(approval_status: APPROVAL_STATUS_CODES[:approved])
  end

  def self.approval_requested
    where(approval_status: APPROVAL_STATUS_CODES[:requested])
  end

  def approval_status
    APPROVAL_STATUS[super.to_i] || APPROVAL_STATUS[0]
  end

  def approval_status=(key)
    super(APPROVAL_STATUS_CODES[key.to_sym])
  end

  def not_approved?
    approval_status == :not_approved
  end

  def approved?
    approval_status == :approved
  end

  def approval_requested?
    approval_status == :requested
  end

  def request_approval
    self.approval_status = :requested
    save!
    # CurationMailer.materials_require_approval(self, User.current_user).deliver_later
  end

  def self.approval_required?
    TeSS::Config.feature['material_under_admin_approval'] && !User.current_user&.is_admin? ## CHANGE IT 
  end

  private

  def set_approval_status
    # sets to `:requested` by default, otherwise admin chooses
    if self.class.approval_required?
      self.approval_status = :requested
    end
  end

  def reset_approval_status
    if self.class.approval_required?
      if url_changed?
        self.approval_status = :not_approved
      end
    end
  end

  def log_approval_status_change
    if approval_status_changed?
      old = (APPROVAL_STATUS[approval_status_before_last_save.to_i] || APPROVAL_STATUS[0]).to_s
      new = approval_status.to_s
      create_activity(:approval_status_changed, owner: User.current_user, parameters: { old: old, new: new })
    end
  end

  def loggable_changes
    super - %w[approval_status]
  end
end
