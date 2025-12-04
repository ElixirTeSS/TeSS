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
    property :author, -> (material) { 
      material.authors.map { |a| 
        author_hash = { "@type" => "Person", "name" => a.full_name }
        author_hash["@id"] = "https://orcid.org/#{a.orcid}" if a.orcid.present?
        author_hash
      } 
    }
    property :contributor, -> (material) { 
      material.contributors.map { |c| 
        contributor_hash = { "@type" => "Person", "name" => c.full_name }
        contributor_hash["@id"] = "https://orcid.org/#{c.orcid}" if c.orcid.present?
        contributor_hash
      } 
    }
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
    }, condition: -> (material) { material.licence != 'notspecified' }
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
