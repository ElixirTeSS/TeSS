# frozen_string_literal: true

module Bioschemas
  class CourseGenerator < Generator
    def self.type
      'Course'
    end

    def self.bioschemas_profile
      'https://bioschemas.org/profiles/Course/0.10-DRAFT'
    end

    property :name, :title
    property :alternateName, :subtitle
    property :url, :url
    property :description, :description
    property :keywords, :keywords
    property :provider, ->(event) { event.host_institutions.map { |i| { '@type' => 'Organization', name: i } } }
    property :audience, lambda { |event|
      event.target_audience.map { |audience| { '@type' => 'Audience', 'audienceType' => audience } }
    }
    property :about, lambda { |event|
      event.scientific_topics.map { |t| term(t) }
    }
    property :hasCourseInstance, lambda { |event|
      [Bioschemas::CourseInstanceGenerator.new(event).generate.except('@id')]
    }
  end
end
