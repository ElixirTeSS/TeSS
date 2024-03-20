# frozen_string_literal: true

module Bioschemas
  class LearningResourceGenerator < Generator
    def self.type
      'LearningResource'
    end

    def self.bioschemas_profile
      'https://bioschemas.org/profiles/TrainingMaterial/1.0-RELEASE'
    end

    property :name, :title
    property :url, :url
    property :description, :description
    property :keywords, :keywords
    property :author, ->(material) { material.authors.map { |p| person(p) } }
    property :contributor, ->(material) { material.contributors.map { |p| person(p) } }
    property :audience, lambda { |material|
      material.target_audience.map { |audience| { '@type' => 'Audience', 'audienceType' => audience } }
    }
    property :about, lambda { |material|
      material.scientific_topics.map { |t| term(t) }
    }
    property :dateCreated, :remote_created_date
    property :dateModified, :remote_updated_date
    property :license, lambda { |material|
      LicenceDictionary.instance.lookup_value(material.licence, 'reference') ||
        LicenceDictionary.instance.lookup_value(material.licence, 'url') ||
        material.licence
    }
    property :educationalLevel, :difficulty_level,
             condition: ->(event) { event.difficulty_level != 'notspecified' }
  end
end
