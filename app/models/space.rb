class Space < ApplicationRecord
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

  THEMES = ['default', 'green', 'blue', 'space'].freeze
  validates :theme, inclusion: { in: THEMES, allow_blank: true }

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
end
