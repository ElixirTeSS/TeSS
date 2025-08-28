module Bioschemas
  class CourseGenerator < Generator
    def self.type
      'Course'
    end

    def self.bioschemas_profile
      'https://bioschemas.org/profiles/Course/1.0-RELEASE'
    end

    property :name, :title
    property :alternateName, :subtitle
    property :url, :url
    property :description, :description
    property :keywords, :keywords
    property :provider, -> (event) { event.host_institutions.map { |i| { '@type' => 'Organization', name: i } } }
    property :inLanguage, :language
    property :audience, -> (event) {
      event.target_audience.map { |audience| { '@type' => 'Audience', 'audienceType' => audience } }
    }
    property :about, -> (event) {
      event.scientific_topics.map { |t| term(t) }
    }
    property :hasCourseInstance, -> (event) {
      [Bioschemas::CourseInstanceGenerator.new(event).generate.except('@id')]
    }
    property :coursePrerequisites, -> (event) {
      markdown_to_array(event.prerequisites)
    }
    property :teaches, -> (event) {
      markdown_to_array(event.learning_objectives)
    }
    property :mentions, -> (material) { external_resources(material) }
  end
end
