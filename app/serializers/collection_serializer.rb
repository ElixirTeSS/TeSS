# frozen_string_literal: true

class CollectionSerializer < ApplicationSerializer
  attributes :id, :slug, :title, :description, :image_url, :keywords, :created_at, :updated_at

  has_many :events
  has_many :materials
end
