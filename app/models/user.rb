class User < ActiveRecord::Base
  attr_accessor :login #, :email, :username

  has_one :profile, dependent: :destroy
  has_many :materials
  belongs_to :role
  after_create :set_default_role, :set_default_profile

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable,
         :authentication_keys => [:login]

  validates :username,
            :presence => true,
            :case_sensitive => false

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


end