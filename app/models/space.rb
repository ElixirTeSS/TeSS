class Space < ApplicationRecord
  has_image(placeholder: TeSS::Config.placeholder['content_provider'])

  def self.current_space=(space)
    Thread.current[:current_space] = space
  end

  def self.current_space
    Thread.current[:current_space] || Space.default
  end

  def self.default
    DefaultSpace.new
  end

  def logo_alt
    "#{title} logo"
  end
end
