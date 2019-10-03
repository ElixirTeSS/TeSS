class User < ApplicationRecord
  include ActionView::Helpers::ApplicationHelper

  include PublicActivity::Common

  acts_as_token_authenticatable
  include Gravtastic
  gravtastic :secure => true, :size => 250

  extend FriendlyId
  friendly_id :username, use: :slugged

  attr_accessor :login
  attr_accessor :processing_consent

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      text :username
      text :email
    end
    # :nocov:
  end

  has_one :profile, inverse_of: :user, dependent: :destroy
  has_many :materials
  has_many :packages, dependent: :destroy
  has_many :workflows, dependent: :destroy
  has_many :content_providers
  has_many :events
  has_many :nodes
  belongs_to :role, optional: true
  has_many :subscriptions, dependent: :destroy
  has_many :stars, dependent: :destroy
  has_one :ban, dependent: :destroy, inverse_of: :user

  before_create :set_default_role, :set_default_profile
  before_create :skip_email_confirmation_for_non_production
  before_update :skip_email_reconfirmation_for_non_production
  before_destroy :reassign_owner
  after_update :react_to_role_change

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :authentication_keys => [:login]

  validates :username,
            :presence => true,
            :case_sensitive => false,
            :uniqueness => true

  validate :consents_to_processing, on: :create, unless: ->(user) { user.using_omniauth? || User.current_user.try(:is_admin?) }

  accepts_nested_attributes_for :profile

  attr_accessor :publicize_email

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_h).where(["lower(username) = :value OR lower(email) = :value", {:value => login.downcase}]).first
    else
      where(conditions.to_h).first
    end
  end

  def set_default_role
    self.role ||= Role.fetch(TeSS::Config.default_role || 'registered_user')
  end

  def set_default_profile
    self.profile ||= Profile.new
    self.profile.email = (email || unconfirmed_email) if (publicize_email.to_s == '1')
  end

 # Check if user has a particular role
  def has_role?(role)
    self.role && self.role.name == role.to_s
  end

  def is_admin?
    self.has_role?('admin')
  end

  # Check if user is owner of a resource
  def is_owner?(resource)
    return false if resource.nil?
    return false if !resource.respond_to?("user".to_sym)
    if self == resource.user
      return true
    else
      return false
    end
  end

  def is_curator?
    self.has_role?('curator')
  end

  def skip_email_confirmation_for_non_production
    # In development and test environments, set the user as confirmed
    # after creation but before save
    # so no confirmation emails are sent
    self.skip_confirmation! unless Rails.env.production?
  end

  def skip_email_reconfirmation_for_non_production
    unless Rails.env.production?
      self.unconfirmed_email = nil
      self.skip_reconfirmation!
    end
  end

  def self.get_default_user
    where(role_id: Role.fetch('default_user').id).first_or_create!(username: 'default_user',
                                                                   email: TeSS::Config.contact_email,
                                                                   password: SecureRandom.base64,
                                                                   processing_consent: '1')
  end

  def name
    "#{username}".tap do |n|
      n << " (#{full_name})" unless full_name.blank?
    end
  end

  def full_name
    profile.full_name if profile
  end

  def self.current_user=(user)
    Thread.current[:current_user] = user
  end

  def self.current_user
    Thread.current[:current_user]
  end

  # Keeps adding numbers to the end of a given username until it is unique
  def self.unique_username(username)
    unique_username = username
    number = 0

    while User.where(username: unique_username).any?
      unique_username = "#{username}#{number += 1}"
    end

    unique_username
  end

  def self.from_omniauth(auth)
    # TODO: Decide what to do about users who have an account but authenticate later on via Elixir AAI.
    # TODO: The code below will update their account to note the Elixir auth. but leave their password intact;
    # TODO: is this what we should be doing?
    #user = User.where(:provider => auth.provider, :uid => auth.uid).first
    # `auth.info` fields: email, first_name, gender, image, last_name, name, nickname, phone, urls
    user = User.where(uid: auth.uid, provider: auth.provider).first ||
        User.where(email: auth.info.email).first
    if user
      if user.provider.nil? and user.uid.nil?
        user.uid = auth.uid
        user.provider = auth.provider
        user.save
      end
    else
      user = User.new(provider: auth.provider,
                      uid: auth.uid,
                      email: auth.info.email,
                      username: User.username_from_auth_info(auth.info),
                      profile_attributes: { firstname: auth.info.first_name,
                                            surname: auth.info.last_name }
      )
      user.skip_confirmation!
    end

    user
  end

  # Used by `simple_form` when presenting a collection (i.e. for a <select> tag)
  def to_label
    "#{username} (#{email})"
  end

  def banned?
    ban.present?
  end

  def shadowbanned?
    banned? && ban.shadow?
  end

  def self.shadowbanned
    joins(:ban).where(bans: { shadow: true })
  end

  def using_omniauth?
    provider.present? && uid.present?
  end

  def password_required?
    if using_omniauth?
      false
    else
      super
    end
  end

  # Generate a unique username. Usernames provided by AAI may already be in use.
  def self.username_from_auth_info(auth_info)
    user_name = auth_info.nickname
    user_name ||= auth_info.openid
    user_name ||= auth_info.email.split('@').first if auth_info.email
    user_name ||= 'user'

    User.unique_username(user_name)
  end

  def self.with_role(*roles)
    joins(:role).where(roles: { name: Array(roles).map { |role| role.is_a?(Role) ? role.name : role } })
  end

  def self.unbanned
    joins('LEFT OUTER JOIN "bans" on "bans"."user_id" = "users"."id"').where(bans: { id: nil })
  end

  def created_resources
    materials + events
  end

  private

  def reassign_owner
    # Material.where(:user => self).each do |material|
    #   material.update_attribute(:user, get_default_user)
    # end
    # Event.where(:user => self).each do |event|
    #   event.update_attribute(:user_id, get_default_user.id)
    # end
    # ContentProvider.where(:user => self).each do |content_provider|
    #   content_provider.update_attribute(:user_id, get_default_user.id)
    # end
    # Node.where(:user => self).each do |node|
    #   node.update_attribute(:user_id, get_default_user.id)
    # end
    default_user = User.get_default_user
    self.materials.each{|x| x.update_attribute(:user, default_user) } if self.materials.any?
    self.events.each{|x| x.update_attribute(:user, default_user) } if self.events.any?
    self.content_providers.each{|x| x.update_attribute(:user, default_user)} if self.content_providers.any?
    self.nodes.each{|x| x.update_attribute(:user, default_user)} if self.nodes.any?
  end

  def react_to_role_change
    if saved_change_to_role_id?
      create_activity(:change_role, owner: User.current_user, parameters: { old: role_id_before_last_save,
                                                                            new: role_id })
      Sunspot.index(created_resources.to_a) if TeSS::Config.solr_enabled
    end
  end

  def consents_to_processing
    unless processing_consent
      errors.add(:base, 'You must consent to TeSS processing your data in order to register')

      false
    end
  end
end
