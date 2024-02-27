class Source < ApplicationRecord
  include LogParameterChanges
  include HasTestJob
  include HasAssociatedNodes

  APPROVAL_STATUS = {
    0 => :not_approved,
    1 => :requested,
    2 => :approved
  }.freeze

  APPROVAL_STATUS_CODES = APPROVAL_STATUS.invert.freeze

  include PublicActivity::Model
  include Searchable

  belongs_to :user
  belongs_to :content_provider

  validates :url, :method, presence: true
  validates :url, url: true
  validates :approval_status, inclusion: { in: APPROVAL_STATUS.values }
  validates :method, inclusion: { in: -> (_) { TeSS::Config.user_ingestion_methods } },
            unless: -> { User.current_user&.is_admin? || User.current_user&.has_role?(:scraper_user) }
  validate :check_method

  before_create :set_approval_status
  before_update :log_approval_status_change
  before_update :reset_approval_status

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      string :sort_title do
        title
      end
      time :created_at
      time :updated_at
      time :finished_at
      string :url
      string :method do
        ingestor_title
      end
      string :content_provider do
        self.content_provider.try(:title)
      end
      string :node, multiple: true do
        associated_nodes.pluck(:name)
      end
      string :approval_status do
        I18n.t("sources.approval_status.#{approval_status}")
      end
      integer :user_id
      boolean :enabled
    end
    # :nocov:
  end

  # For compatibility with views that render arbitrary lists of user-creatable resources (e.g. curation page)
  def title
    "#{content_provider.title}: #{ingestor_title}"
  end

  def ingestor_title
    ingestor_class.config[:title]
  end

  def ingestor_class
    Ingestors::IngestorFactory.get_ingestor(method)
  end

  def self.facet_fields
    %w( content_provider node method enabled approval_status )
  end

  def self.check_exists(source_params)
    given_source = self.new(source_params)
    source = nil

    if given_source.url.present?
      source = self.find_by_url(given_source.url)
    end

    source
  end

  def self.enabled
    where(enabled: true)
  end

  def check_method
    errors.add(:method, 'is invalid') unless Ingestors::IngestorFactory.valid_ingestor?(method)
  end

  def self.approved
    where(approval_status: APPROVAL_STATUS_CODES[:approved])
  end

  def self.approval_requested
    where(approval_status: APPROVAL_STATUS_CODES[:requested])
  end

  def approval_status
    APPROVAL_STATUS[super] || APPROVAL_STATUS[0]
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
    CurationMailer.source_requires_approval(self, User.current_user).deliver_later
  end

  def self.approval_required?
    TeSS::Config.feature['user_source_creation'] && !User.current_user&.is_admin?
  end

  private

  def set_approval_status
    if self.class.approval_required?
      self.approval_status = :not_approved
    else
      self.approval_status = :approved
    end
  end

  def reset_approval_status
    if self.class.approval_required?
      if method_changed? || url_changed?
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
    super - %w[approval_status log records_read records_written resources_added resources_updated resources_rejected
               finished_at]
  end
end
