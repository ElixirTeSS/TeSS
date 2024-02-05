module HasEdamTerms
  extend ActiveSupport::Concern

  def scientific_topics_and_synonyms
    scientific_topics.map do |term|
      [term.preferred_label] + term.has_exact_synonym + term.has_narrow_synonym
    end.flatten.uniq
  end

  def operations_and_synonyms
    operations.map do |term|
      [term.preferred_label] + term.has_exact_synonym + term.has_narrow_synonym
    end.flatten.uniq
  end
end
