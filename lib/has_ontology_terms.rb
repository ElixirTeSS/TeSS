# A module to handle association of ontology terms to an ActiveRecord model.
# use like so (make sure to use a plural):
#
# class Model < ApplicationRecord
#
#   has_ontology_terms(:operations, branch: EDAM.operations)
#
# end
#
# This will make the following methods available on Model:
# Model#operations           - Return a list of OntologyTerm objects linked to the model.
# Model#operations=          - Set the list of OntologyTerm objects.
# Model#operation_names      - Return a list of names (labels) of the ontology terms linked to the model.
# Model#operation_names=     - Set the list ontology terms from a list of names. Looks up terms based on their RDF::RDFS.label, OBO.hasExactSynonym or OBO.hasNarrowSynonym.
# Model#operation_uris       - Return a list of URIs of the ontology terms linked to the model.
# Model#operation_uris=      - Set the list ontology terms from a list of term URIs.
# Model#operation_links      - The Rails has_many association that joins the model to the ontology terms.

module HasOntologyTerms
  def self.included(mod)
    mod.extend(ClassMethods)
  end

  module ClassMethods
    def has_ontology_terms(association_name,
                           ontology: nil,
                           branch: nil,
                           ontologies: nil)
      unless ontologies
        ontology ||= Edam::Ontology.instance
        # :_ is essentially a wildcard, meaning it will match any branch.
        branch ||= :_
      else
        # ontologies is an array of hashes with keys :ontology and :branch
        ontologies = ontologies.map do |ontology_specification|
          { ontology: ontology_specification[:ontology] || Edam::Ontology.instance,
            branch: ontology_specification[:branch] || :_ }
        end
      end

      method = association_name.to_s
      singular = association_name.to_s.singularize
      links_method = "#{singular}_links"
      uris_method = "#{singular}_uris"
      names_method = "#{singular}_names"

      # General has_many for ontology term links
      unless method_defined?(:ontology_term_links)
        has_many :ontology_term_links,
                 as: :resource,
                 dependent: :destroy
      end

      # Specific ontology term links for the given field
      has_many links_method.to_sym, -> { where(field: association_name.to_s) },
               class_name: 'OntologyTermLink',
               as: :resource,
               dependent: :destroy,
               inverse_of: :resource

      # Previously used cattr_accessor, which uses "@@" variables that mess with inheritance.
      # So we do this instead (use "@" class vars)...
      def self.ontology_term_fields
        @ontology_term_fields ||= []
      end

      self.ontology_term_fields << method.to_sym

      define_method "#{links_method}=" do |links|
        send(links_method).reset
        current_links = send(links_method).to_a
        to_keep = []

        links.reject(&:blank?).map do |link|
          idx = current_links.index { |l| l.term_uri == link.term_uri }
          if idx
            match = current_links.delete_at(idx)
            to_keep << match
          else
            to_keep << link
          end
        end

        current_links.each(&:mark_for_destruction) # Now contains only redundant records

        super(to_keep)
      end

      # OntologyTerm objects
      define_method method do
        send(links_method).map(&:ontology_term).uniq
      end

      define_method "#{method}=" do |terms|
        send("#{links_method}=", terms.uniq.map { |term| send(links_method).build(term_uri: term.uri) if term.present? && term.uri }.compact)
      end

      # Names/Labels
      define_method names_method do
        send(method).map(&:preferred_label).uniq
      end

      define_method "#{names_method}=" do |names|
        terms = []
        [names].flatten.each do |name|
          unless name.blank?
            st = if ontologies
                   # TODO: if name is found in first ontology, should it skip others?
                   ontologies.map do |ontology_specification|
                     [ontology_specification[:ontology].\
                        scoped_lookup_by_name_or_synonym(name,
                                                         ontology_specification[:branch])]
                   end
                 else
                   [ontology.scoped_lookup_by_name_or_synonym(name, branch)]
                 end
            terms += st
          end
        end
        send("#{method}=", terms.flatten.compact.uniq)
      end

      # URIs
      define_method uris_method do
        send(method).map(&:uri).uniq
      end

      define_method "#{uris_method}=" do |uris|
        terms = if ontologies
                  ontologies.map do |ontology_specification|
                    uris.map { |uri| ontology_specification[:ontology].lookup(uri) }
                  end.flatten
                else
                  uris.map { |uri| ontology.lookup(uri) }
                end

        send("#{method}=", terms)
      end
    end
  end
end
