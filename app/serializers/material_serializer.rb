# frozen_string_literal: true

class MaterialSerializer < ApplicationSerializer
  attributes :id, :title, :url, :description,
             :keywords, :resource_type, :other_types, :scientific_topics, :operations, :fields, :external_resources,
             :doi, :licence, :version, :status,
             :contact, :contributors, :authors,
             :difficulty_level, :target_audience, :prerequisites, :syllabus, :learning_objectives, :subsets,
             :date_created, :date_modified, :date_published, :remote_updated_date, :remote_created_date,
             :slug, :last_scraped, :scraper_record, :created_at, :updated_at

  belongs_to :user
  belongs_to :content_provider
  has_many :nodes
  has_many :collections
  has_many :events
end
