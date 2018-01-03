class Ban < ActiveRecord::Base
  belongs_to :user
  belongs_to :banner, class_name: 'User'
end
