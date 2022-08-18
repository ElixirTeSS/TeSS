class EditSuggestion < ApplicationRecord
  belongs_to :suggestible, polymorphic: true
  after_create :init_data_fields

  has_ontology_terms(:scientific_topics, branch: OBO_EDAM.topics)
  has_ontology_terms(:operations, branch: OBO_EDAM.operations)

  # data_fields: json field for storing any additional parameters
  # such as latitude, longitude &c.

  def init_data_fields
    self.data_fields = {} if data_fields.nil?
  end

  def accept_suggestion(field, term)
    if drop_term(field, term)
      if suggestible.class.ontology_term_fields.include?(field.to_sym)
        suggestible.ontology_term_links.create!(field: field, term_uri: term.uri)
      end
      destroy if redundant?
    end
  end

  def reject_suggestion(field, term)
    if drop_term(field, term)
      destroy if redundant?
    end
  end

  def accept_data(field)
    if suggestible.update_attribute(field, data_fields[field])
      data_fields.delete(field)
      save!
      destroy if redundant?
    end
  end

  def reject_data(field)
    data_fields.delete(field)
    save!
    destroy if redundant?
  end

  def data
    !data_fields.blank?
  end

  private

  def drop_term(field, term)
    link = ontology_term_links.find_by(term_uri: term.uri, field: field)
    if link
      link.destroy
      self.reload
    end
  end

  def redundant?
    ontology_term_links.empty? && !data
  end
end
