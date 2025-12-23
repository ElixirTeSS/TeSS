class Space < ApplicationRecord
  FEATURES = %w[events materials elearning_materials learning_paths workflows collections trainers content_providers nodes].freeze

  include PublicActivity::Common
  include LogParameterChanges

  belongs_to :user
  has_many :materials, dependent: :nullify
  has_many :events, dependent: :nullify
  has_many :workflows, dependent: :nullify
  has_many :collections, dependent: :nullify
  has_many :learning_paths, dependent: :nullify
  has_many :learning_path_topics, dependent: :nullify
  has_many :space_roles, dependent: :destroy
  has_many :space_role_users, through: :space_roles, source: :user, class_name: 'User'
  has_many :administrator_roles, -> { where(key: :admin) }, class_name: 'SpaceRole'
  has_many :administrators, through: :administrator_roles, source: :user, class_name: 'User'

  validates :theme, inclusion: { in: TeSS::Config.themes.keys, allow_blank: true }
  validate :disabled_features_valid?

  has_image(placeholder: TeSS::Config.placeholder['content_provider'])

  def self.current_space=(space)
    Thread.current[:current_space] = space
  end

  def self.current_space
    Thread.current[:current_space] || Space.default
  end

  def self.default
    DefaultSpace.new
  end

  def logo_alt
    "#{title} logo"
  end

  def url
    "https://#{host}"
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

  private

  def disabled_features_valid?
    disabled_features.each do |feature|
      next if feature.blank?
      unless FEATURES.include?(feature)
        errors.add(:disabled_features, :inclusion)
      end
    end
  end
end
