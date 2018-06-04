class OntologyTermLink < ActiveRecord::Base; end

class PopulateFieldInExistingOntologyTermLinks < ActiveRecord::Migration
  def change
    OntologyTermLink.where(field: nil).where('term_uri LIKE ?', 'http://edamontology.org/topic_%').update_all(field: HasScientificTopics::FIELD_NAME)
    OntologyTermLink.where(field: nil).where('term_uri LIKE ?', 'http://edamontology.org/operation_%').update_all(field: HasOperations::FIELD_NAME)
  end
end
