module HasEdamTerms
  extend ActiveSupport::Concern

  def scientific_topics_and_synonyms
    edam_term_names_and_synonyms(scientific_topics)
  end

  def operations_and_synonyms
    edam_term_names_and_synonyms(operations)
  end

  private

  def edam_term_names_and_synonyms(terms)
    terms.map do |term|
      [term.preferred_label] + term.has_exact_synonym + term.has_narrow_synonym
    end.flatten.uniq
  end
end
