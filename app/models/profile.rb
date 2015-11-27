class Profile < ActiveRecord::Base
  belongs_to :user
  attr_accessor :email
=begin
  searchable do
    text :firstname
    text :surname
  end
=end
  # TODO:
  # Add validations for these fields (default nil, except email)
  # firstname:text surname:text image_url:text email:text website:text

end
