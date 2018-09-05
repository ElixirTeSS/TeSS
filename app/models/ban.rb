class Ban < ApplicationRecord
  belongs_to :user
  belongs_to :banner, class_name: 'User'
end
