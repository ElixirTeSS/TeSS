class OntologyTermLink < ActiveRecord::Base; end

class PopulateFieldInExistingOntologyTermLinks < ActiveRecord::Migration[4.2]
  def change
    OntologyTermLink.where(field: nil).where('term_uri LIKE ?', 'http://edamontology.org/topic_%').update_all(field: 'scientific_topics')
    OntologyTermLink.where(field: nil).where('term_uri LIKE ?', 'http://edamontology.org/operation_%').update_all(field: 'operations')
  end
end
