# A module to handle association of ontology terms to an ActiveRecord model.
# use like so (make sure to use a plural):
#
# class Model < ApplicationRecord
#
#   has_ontology_terms(:operations, branch: OBO_EDAM.operations)
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
    def has_ontology_terms(association_name, ontology: EDAM::Ontology.instance, branch: :_) # :_ is essentially a wildcard, meaning it will match any branch.
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

      cattr_accessor :ontology_term_fields
      self.ontology_term_fields ||= []
      self.ontology_term_fields << method.to_sym

      # OntologyTerm objects
      define_method method do
        send(links_method).map(&:ontology_term).uniq
      end

      define_method "#{method}=" do |terms|
        send("#{links_method}=", terms.uniq.map { |term| send(links_method).build(term_uri: term.uri) if term && term.uri }.compact)
      end

      # Names/Labels
      define_method names_method do
        send(method).map(&:preferred_label).uniq
      end

      define_method "#{names_method}=" do |names|
        terms = []
        [names].flatten.each do |name|
          unless name.blank?
            st = [ontology.scoped_lookup_by_name(name, branch)].compact # FIXME: This is probably too EDAM specific
            st = ontology.find_by(OBO.hasExactSynonym, name) if st.empty?
            st = ontology.find_by(OBO.hasNarrowSynonym, name) if st.empty?
            terms += st
          end
        end
        send("#{method}=", terms.uniq)
      end

      # URIs
      define_method uris_method do
        send(method).map(&:uri).uniq
      end

      define_method "#{uris_method}=" do |uris|
        send("#{method}=", uris.map { |uri| ontology.lookup(uri) })
      end
    end
  end
end
