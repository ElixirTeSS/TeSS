module Bioschemas
  class LearningResourceGenerator < Generator
    def self.type
      'LearningResource'
    end

    def self.bioschemas_profile
      'https://bioschemas.org/profiles/TrainingMaterial/1.0-RELEASE'
    end

    property :name, :title
    property :learningResourceType, :resource_type
    property :url, :url
    property :identifier, :doi
    property :version, :version
    property :description, :description
    property :keywords, :keywords
    property :author, -> (material) { material.authors.map { |p| person(p) } }
    property :contributor, -> (material) { material.contributors.map { |p| person(p) } }
    property :provider, -> (material) { provider(material) }
    property :audience, -> (material) {
      material.target_audience.map { |audience| { '@type' => 'Audience', 'audienceType' => audience } }
    }
    property :about, -> (material) {
      material.scientific_topics.map { |t| term(t) }
    }
    property :dateCreated, :date_created
    property :dateModified, :date_modified
    property :datePublished, :date_published
    property :creativeWorkStatus, :status
    property :license, -> (material) {
      LicenceDictionary.instance.lookup_value(material.licence, 'reference') ||
        LicenceDictionary.instance.lookup_value(material.licence, 'url') ||
        material.licence
    }
    property :educationalLevel, :difficulty_level,
             condition: -> (material) { material.difficulty_level != 'notspecified' }
    property :competencyRequired, -> (material) {
      markdown_to_array(material.prerequisites)
    }
    property :teaches, -> (material) {
      markdown_to_array(material.learning_objectives)
    }
    property :mentions, -> (material) { external_resources(material) }
  end
end
