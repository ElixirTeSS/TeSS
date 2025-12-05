require 'uri'

class Profile < ApplicationRecord
  include HasOrcid

  auto_strip_attributes :firstname, :surname, :website, squish: false
  belongs_to :user, inverse_of: :profile

  before_validation :normalize_orcid
  validates :firstname, :surname, :description, presence: true, if: :public?
  validates :website, url: true, http_url: { allow_inaccessible: true }, allow_blank: true
  validates :orcid, orcid: true, allow_blank: true
  after_validation :check_public
  after_commit :reindex_trainer, on: %i[create update]
  clean_array_fields(:expertise_academic, :expertise_technical, :fields,
                     :interest, :activity, :language, :social_media)
  update_suggestions(:expertise_technical, :interest)

  extend FriendlyId
  friendly_id :full_name, use: :slugged

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

  def authenticate_orcid(orcid)
    existing = Profile.where(orcid: orcid, orcid_authenticated: true)
    self.orcid = orcid
    self.orcid_authenticated = true
    out = self.save

    if out
      existing.each do |profile|
        next if profile == self
        profile.update_column(:orcid_authenticated, false)
      end
    end

    out
  end

  private

  def check_public
    public ? self.type = 'Trainer' : self.type = 'Profile'
  end

  def should_generate_new_friendly_id?
    firstname_changed? or surname_changed?
  end

  # This is needed if the `public` status of the profile changes when it is already instantiated - it won't be cast
  # to a Trainer object and indexed by solr (only Trainer class is `searchable`).
  def reindex_trainer
    return unless TeSS::Config.solr_enabled
    becomes(Trainer).solr_index
  end
end
