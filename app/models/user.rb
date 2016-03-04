class User < ActiveRecord::Base
  acts_as_token_authenticatable
  include Gravtastic
  gravtastic :secure => true, :size => 250

  extend FriendlyId
  friendly_id :username, use: :slugged

  attr_accessor :login
  unless SOLR_ENABLED==false
    searchable do
      text :username
      text :email
    end
  end

  has_one :profile
  has_many :materials
  has_many :packages
  has_many :workflows
  belongs_to :role

  before_create :set_default_role, :set_default_profile
  after_create :skip_email_confirmation_for_non_production

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

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_h).where(["lower(username) = :value OR lower(email) = :value", {:value => login.downcase}]).first
    else
      where(conditions.to_h).first
    end
  end

  #private

  def set_default_role
    self.role ||= Role.find_by_name('registered_user')
  end

  def set_default_profile
    self.profile ||= Profile.new(email: self[:email])
  end

  def is_admin?
    if !self.role
      return false
    end
    if self.role.name == 'admin'
      return true
    end
    return false
  end

  def is_api_user?
    if !self.role
      return false
    end
    if self.role.name == 'api_user'
      return true
    end
    return false
  end

  def is_registered_user?
    if !self.role
      return false
    end
    if self.role.name == 'registered_user'
      return true
    end
    return false
  end

  def skip_email_confirmation_for_non_production
    # In development and test environments, set the user as confirmed
    # after creation but before save
    # so no confirmation emails are sent
    self.confirm unless Rails.env.production?
  end

  def set_as_admin
    role = Role.find_by_name('admin')
    if role
      self.role = role
      self.save!
    else
      puts 'Sorry, no admin for you.'
    end
  end

end
