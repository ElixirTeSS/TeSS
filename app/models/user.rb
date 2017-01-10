class User < ActiveRecord::Base
  include ActionView::Helpers::ApplicationHelper

  include PublicActivity::Common

  has_paper_trail

  acts_as_token_authenticatable
  include Gravtastic
  gravtastic :secure => true, :size => 250

  extend FriendlyId
  friendly_id :username, use: :slugged

  attr_accessor :login

  if SOLR_ENABLED
    searchable do
      text :username
      text :email
    end
  end

  has_one :profile, :dependent => :destroy
  has_many :materials
  has_many :packages, :dependent => :destroy
  has_many :workflows, :dependent => :destroy
  has_many :content_providers
  has_many :events
  has_many :nodes
  belongs_to :role

  before_create :set_registered_user_role, :set_default_profile
  after_create :skip_email_confirmation_for_non_production

  before_destroy :reassign_owner

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable,
         :authentication_keys => [:login]

  validates :username,
            :presence => true,
            :case_sensitive => false,
            :uniqueness => true

  validates :email,
            :presence => true,
            :case_sensitive => false

  validates_format_of :email, :with => Devise.email_regexp

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

  def set_registered_user_role
    self.role ||= Role.fetch('registered_user')
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

  def is_default_user?
    self.has_role?('default_user')
  end

  def is_curator?
    self.has_role?('curator')
  end

  def skip_email_confirmation_for_non_production
    # In development and test environments, set the user as confirmed
    # after creation but before save
    # so no confirmation emails are sent
    self.confirm unless Rails.env.production?
  end

  def set_as_admin
    role = Role.fetch('admin')
    if role
      self.role = role
      self.save!
    else
      puts 'Sorry, no admin for you.'
    end
  end

  def self.get_default_user
    where(role_id: Role.fetch('default_user').id).first_or_create(username: 'default_user',
                                                                  email: CONTACT_EMAIL,
                                                                  password: SecureRandom.base64)
  end

  def name
    n = "#{username}"
    if self.profile && self.profile.firstname
      n += " (#{self.profile.firstname} #{self.profile.surname})"
    end
  end

  def self.current_user=(user)
    Thread.current[:current_user] = user
  end

  def self.current_user
    Thread.current[:current_user]
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
end
