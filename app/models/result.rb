class Result < ApplicationRecord

  belongs_to :source

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      datetime :finished
      string :source do
        self.source.try(:url)
      end
    end
    # :nocov:
  end


end
