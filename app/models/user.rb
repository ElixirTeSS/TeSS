class User < ActiveRecord::Base
  acts_as_token_authenticatable

  attr_accessor :login
  unless SOLR_ENABLED==false
    searchable do
      text :username
      text :email
    end
  end

  has_one :profile, dependent: :destroy
  has_many :materials
  has_many :packages
  has_many :workflows
  belongs_to :role

  after_create :set_default_role, :set_default_profile, :skip_email_confirmation!

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

  validates_format_of :email,:with => Devise.email_regexp

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_h).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions.to_h).first
    end
  end

  #private

  def set_default_role
    self.role ||= Role.find_by_name('registered_user')
  end

  def set_default_profile
    if self.profile.nil?
      self.create_profile()
      self.profile[:email] = self[:email]
      self.profile.save!
    end
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

  def skip_email_confirmation!
    # In development environment, set the user as confirmed after creation
    # so no confirmation emails are sent
    self.confirm! if Rails.env.development?
  end

end
