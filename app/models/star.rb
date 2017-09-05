class Star < ActiveRecord::Base

  belongs_to :user
  belongs_to :resource, polymorphic: true

  validates :resource_id, presence: true, uniqueness: { scope: [:resource_type, :user_id] }
  validate :check_resource_exists

  private

  def check_resource_exists
    begin
      resource_class = resource_type.constantize
      errors.add(:resource, 'is not valid') unless resource_class.exists?(resource_id)
    rescue NameError
      errors.add(:resource_type, 'is not valid')
    end
  end
end
