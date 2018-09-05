class PackageEvent < ApplicationRecord
  belongs_to :event
  belongs_to :package

  include PublicActivity::Common

  self.primary_key = 'id'

  after_save :log_activity

  def log_activity
    self.package.create_activity(:add_event, owner: User.current_user,
                                 parameters: { event_id: self.event_id, event_title: self.event.title })
    self.event.create_activity(:add_to_package, owner: User.current_user,
                               parameters: { package_id: self.package_id, package_title: self.package.title })
  end
end
