class Space < ApplicationRecord
  FEATURES = %w[events materials elearning_materials learning_paths workflows collections trainers content_providers nodes spaces].freeze

  include PublicActivity::Common
  include LogParameterChanges

  belongs_to :user
  has_many :materials
  has_many :events
  has_many :workflows
  has_many :collections
  has_many :learning_paths
  has_many :learning_path_topics
  has_many :subscriptions
  has_many :space_roles
  has_many :space_role_users, through: :space_roles, source: :user, class_name: 'User'
  has_many :administrator_roles, -> { where(key: :admin) }, class_name: 'SpaceRole'
  has_many :administrators, through: :administrator_roles, source: :user, class_name: 'User'
  has_and_belongs_to_many :groups

  auto_strip_attributes :title, :description, :host

  validates :title, presence: true
  validates :host, presence: true, uniqueness: true, format: /\A[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)*\z/i
  validates :theme, inclusion: { in: TeSS::Config.themes.keys, allow_blank: true }
  validate :disabled_features_valid?

  before_destroy :handle_associations_on_destroy

  has_image(placeholder: TeSS::Config.placeholder['content_provider'])

  def self.current_space=(space)
    Thread.current[:current_space] = space
  end

  def self.current_space
    Thread.current[:current_space] || Space.default
  end

  def self.with_current_space(space)
    old_space = current_space
    old_space = nil if old_space.default?
    self.current_space = space
    yield
  ensure
    self.current_space = old_space
  end

  def self.default
    TeSS::Config.feature['spaces'] ? DefaultSpace.new : GlobalSpace.new
  end

  def logo_alt
    "#{title} logo"
  end

  def url
    "#{TeSS::Config.base_uri.scheme}://#{host}"
  end

  def default?
    false
  end

  def users_with_role(role)
    space_role_users.joins(:space_roles).where(space_roles: { key: role })
  end

  def feature_enabled?(feature)
    if FEATURES.include?(feature)
      TeSS::Config.feature[feature] && !disabled_features.include?(feature)
    else
      TeSS::Config.feature[feature]
    end
  end

  def enabled_features= features
    self.disabled_features = (FEATURES - features)
  end

  def enabled_features
    (FEATURES - disabled_features)
  end

  def is_subdomain?(domain = TeSS::Config.base_uri.domain)
    (host == domain || host.ends_with?(".#{domain}"))
  end

  def ==(other)
    other.is_a?(Space) && self.id == other.id
  end

  private

  def disabled_features_valid?
    disabled_features.each do |feature|
      next if feature.blank?
      unless FEATURES.include?(feature)
        errors.add(:disabled_features, :inclusion)
      end
    end
  end

  def handle_associations_on_destroy
    associations = [
      :materials,
      :events,
      :workflows,
      :collections,
      :learning_paths,
      :learning_path_topics,
      :subscriptions,
    ]

    associations.each do |relation|
      records = send(relation)

      if is_private
        records.delete_all
      else
        # explicitly ask Solr to reindex those records so they reappear under the default space.
        klass = records.klass
        ids = records.pluck(:id)

        records.update_all(space_id: nil)

        if TeSS::Config.solr_enabled && ids.any? && klass.respond_to?(:solr_index)
          klass.where(id: ids).solr_index
        end
      end
    end
    send(:space_roles).delete_all
  end
end
