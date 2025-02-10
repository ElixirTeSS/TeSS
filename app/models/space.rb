class Space < ApplicationRecord
  include PublicActivity::Common
  include LogParameterChanges

  belongs_to :user
  has_many :materials
  has_many :events
  has_many :workflows
  has_many :collections
  has_many :learning_paths
  has_many :learning_path_topics

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
end
