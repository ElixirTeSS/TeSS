module Bioschemas
  class Generator
    attr_reader :resource

    def self.type
      'Thing'
    end

    def initialize(resource)
      @resource = resource
    end

    def generate
      template = {
        '@context' => 'http://schema.org',
        '@id' => routes.polymorphic_url(resource),
        '@type' => self.class.type
      }

      properties.each do |prop, opts|
        attr_or_proc = opts[:attr]
        condition = opts[:condition]
        next if condition && !condition.call(resource)
        if attr_or_proc.respond_to?(:call)
          value = attr_or_proc.call(resource)
        else
          value = resource.send(attr_or_proc)
        end

        next if value.blank?
        template[prop] = value
      end

      template
    end

    def to_json
      JSON.pretty_generate(generate)
    end

    def routes
      self.class.routes
    end

    def self.routes
      @routes ||= Rails.application.routes.url_helpers
    end

    def properties
      self.class.properties
    end

    def self.properties
      @properties ||= {}
    end

    def self.property(name, attr_or_proc, condition: nil)
      properties[name] = { attr: attr_or_proc, condition: condition }
    end

    def self.term(term)
      {
        "@type" => "DefinedTerm",
        "@id" => term.uri,
        "inDefinedTermSet" => term.ontology.uri,
        "name" => term.label,
        "url" => term.uri
      }
    end

    def self.person(person)
      {
        "@type" => "Person",
        "name" => person
      }
    end
  end
end