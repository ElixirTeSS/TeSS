require 'uri'

class Profile < ApplicationRecord
  auto_strip_attributes :firstname, :surname, :website, :orcid, squish: false
  belongs_to :user, inverse_of: :profile

  before_validation :normalize_orcid
  validates :firstname, :surname, :description, presence: true, if: :public?
  validates :website, url: true, http_url: true, allow_blank: true
  validates :orcid, orcid: true, allow_blank: true
  after_validation :check_public
  clean_array_fields(:expertise_academic, :expertise_technical, :fields,
                     :interest, :activity, :language, :social_media)
  update_suggestions(:expertise_technical, :interest)

  extend FriendlyId
  friendly_id :full_name, use: :slugged

  after_update_commit :reindex
  after_destroy_commit :reindex

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      # full text search fields
      text :firstname
      text :surname
      text :description
      # sort title
      string :sort_title do
        full_name.downcase
      end
      # other fields
      integer :user_id
      string :full_name
      string :location
      string :orcid
      string :experience do
        TrainerExperienceDictionary.instance.lookup_value(self.experience, 'title')
      end
      string :expertise_academic, multiple: true
      string :expertise_technical, multiple: true
      string :fields, :multiple => true
      string :interest, multiple: true
      string :activity, multiple: true
      string :language, multiple: true
      string :social_media, multiple: true
      time :updated_at
      boolean :public
    end
    # :nocov:
  end

  def self.facet_fields
    field_list = %w( full_name )
  end

  def full_name
    "#{firstname} #{surname}".strip
  end

  def merge(*others)
    Profile.transaction do
      attrs = attributes
      others.each do |other|
        other.attributes.each do |attr, value|
          if value.is_a?(Array)
            attrs[attr] ||= []
            attrs[attr] |= value
          elsif attrs[attr].blank?
            attrs[attr] = value
          end
        end
      end

      self.update(attrs)
    end
  end

  private

  def normalize_orcid
    return if orcid.blank?
    self.orcid = orcid.strip
    if orcid =~ OrcidValidator::ORCID_ID_REGEX
      self.orcid = "#{OrcidValidator::ORCID_PREFIX}#{orcid}"
    elsif orcid.start_with?(OrcidValidator::ORCID_DOMAIN_REGEX)
      self.orcid = orcid.sub(OrcidValidator::ORCID_DOMAIN_REGEX, OrcidValidator::ORCID_PREFIX)
    end
  end

  def check_public
    public ? self.type = 'Trainer' : self.type = 'Profile'
  end

  def reindex
    if Rails.env.production?
      Trainer.reindex
    end
  end

  def should_generate_new_friendly_id?
    firstname_changed? or surname_changed?
  end

end
