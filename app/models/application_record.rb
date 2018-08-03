class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include HasOntologyTerms
  include HasImage
  include AutocompleteManager
  include ArrayFieldCleaner

end