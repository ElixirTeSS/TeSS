module Bioschemas
  class CourseGenerator < Generator
    def self.type
      'Course'
    end

    property :name, :title
    property :alternateName, :subtitle
    property :url, :url
    property :description, :description
    property :keywords, :keywords
    property :provider, -> (event) { event.host_institutions.map { |i| { '@type' => 'Organization', name: i } } }
    property :audience, -> (event) {
      event.target_audience.map { |audience| { '@type' => 'Audience', 'audienceType' => audience } }
    }
    property :about, -> (event) {
      event.scientific_topics.map { |t| term(t) }
    }
    property :hasCourseInstance, -> (event) {
      [Bioschemas::CourseInstanceGenerator.new(event).generate.except('@id')]
    }
  end
end
