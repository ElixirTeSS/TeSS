# A Space represents an isolated area of the application (its own subdomain
# / host, its own content, and optionally its own set of enabled features).
#
# Spaces can be public or private. Private spaces restrict access to users
# who belong to one of the space's associated Group objects (see
# ApplicationPolicy#shown?). The "current" space for a request is tracked in
# a thread-local variable (see .current_space) and resolved from the request
# host in ApplicationController#set_current_space.
class Space < ApplicationRecord
  # The list of toggleable content-type features a Space may enable/disable.
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
  has_many :space_roles, dependent: :destroy
  has_many :space_role_users, through: :space_roles, source: :user, class_name: 'User'
  has_many :administrator_roles, -> { where(key: :admin) }, class_name: 'SpaceRole'
  has_many :administrators, through: :administrator_roles, source: :user, class_name: 'User'
  has_and_belongs_to_many :groups

  auto_strip_attributes :title, :description, :host

  validates :title, presence: true
  validates :host, presence: true, uniqueness: true, format: /\A[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)*\z/i
  validates :theme, inclusion: { in: TeSS::Config.themes.keys, allow_blank: true }
  validate :disabled_features_valid?

  # ActiveModel validator ensuring a private Space always has at least one
  # Group associated with it, since group membership is what grants access
  # to a private space.
  class CheckPrivateSpace < ActiveModel::Validator
    # Validates that +record+, if private, has at least one associated
    # group. Adds a base error otherwise.
    #
    # record:: the Space instance being validated.
    def validate(record)
    if record.is_private && !(record.group_ids.length > 0)
        record.errors.add(:base, "If the space is private, you must add required groups.")
      end
    end
  end

  validates_with CheckPrivateSpace

  before_destroy :handle_associations_on_destroy

  has_image(placeholder: TeSS::Config.placeholder['content_provider'])

  # Sets the space considered "current" for the executing thread.
  #
  # space:: the Space (or subclass, e.g. DefaultSpace/GlobalSpace) to use as
  #         the current space.
  def self.current_space=(space)
    Thread.current[:current_space] = space
  end

  # Returns:: the Space considered "current" for the executing thread, or
  #           Space.default if none has been set.
  def self.current_space
    Thread.current[:current_space] || Space.default
  end

  # Temporarily overrides the current space for the duration of the given
  # block, restoring the previous value afterwards (even if the block
  # raises).
  #
  # space:: the Space to use as current within the block.
  #
  # Yields:: with no arguments, while +space+ is set as current.
  def self.with_current_space(space)
    old_space = current_space
    old_space = nil if old_space.default?
    self.current_space = space
    yield
  ensure
    self.current_space = old_space
  end

  # Returns:: the default "no space" placeholder: a DefaultSpace if the
  #           +spaces+ feature is enabled, otherwise a GlobalSpace.
  def self.default
    TeSS::Config.feature['spaces'] ? DefaultSpace.new : GlobalSpace.new
  end

  # Returns:: the alt text to use for the space's logo image.
  def logo_alt
    "#{title} logo"
  end

  # Returns:: the fully-qualified URL of this space (scheme + host).
  def url
    "#{TeSS::Config.base_uri.scheme}://#{host}"
  end

  # Returns:: +false+. Overridden by DefaultSpace/GlobalSpace to indicate
  #           the default placeholder space.
  def default?
    false
  end

  # Finds the users who hold a given SpaceRole in this space.
  #
  # role:: the role key (e.g. :admin) to filter by.
  #
  # Returns:: an ActiveRecord::Relation of User records.
  def users_with_role(role)
    space_role_users.joins(:space_roles).where(space_roles: { key: role })
  end

  # Checks whether a given feature is enabled for this space.
  #
  # feature:: String or Symbol feature key. If it is one of ::FEATURES, both
  #           the global TeSS::Config setting and this space's
  #           +disabled_features+ list are consulted; otherwise only the
  #           global TeSS::Config setting is checked.
  #
  # Returns:: +true+ or +false+.
  def feature_enabled?(feature)
    if FEATURES.include?(feature)
      TeSS::Config.feature[feature] && !disabled_features.include?(feature)
    else
      TeSS::Config.feature[feature]
    end
  end

  # Sets the list of enabled features by computing which of ::FEATURES are
  # *not* included, and storing that as +disabled_features+.
  #
  # features:: Array of feature keys that should be enabled.
  def enabled_features= features
    self.disabled_features = (FEATURES - features)
  end

  # Returns:: the Array of feature keys currently enabled for this space
  #           (i.e. ::FEATURES minus +disabled_features+).
  def enabled_features
    (FEATURES - disabled_features)
  end

  # Checks whether this space's host is the given domain, or a subdomain of
  # it.
  #
  # domain:: the domain to compare against; defaults to
  #          <tt>TeSS::Config.base_uri.domain</tt>.
  #
  # Returns:: +true+ or +false+.
  def is_subdomain?(domain = TeSS::Config.base_uri.domain)
    (host == domain || host.ends_with?(".#{domain}"))
  end

  # Equality by id: two Space instances are equal if they are both Space
  # records with the same +id+.
  #
  # other:: the object to compare against.
  #
  # Returns:: +true+ or +false+.
  def ==(other)
    other.is_a?(Space) && self.id == other.id
  end

  private

  # Validation callback ensuring every entry in +disabled_features+ is a
  # recognized feature key from ::FEATURES.
  def disabled_features_valid?
    disabled_features.each do |feature|
      next if feature.blank?
      unless FEATURES.include?(feature)
        errors.add(:disabled_features, :inclusion)
      end
    end
  end

  # before_destroy callback that reassigns or deletes this space's
  # associated records.
  #
  # For a private space, the associated records (materials, events, etc.)
  # are deleted outright. For a public space, they are instead detached
  # (their +space_id+ is set to +nil+) so they "fall back" to the default
  # space, and reindexed in Solr if enabled. The space's SpaceRole records
  # are always deleted.
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
        records.destroy_all
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
  end
end