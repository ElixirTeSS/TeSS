class Result < ApplicationRecord

  belongs_to :source

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      time :finished_at
      string :source do
        self.source.try(:url)
      end
    end
    # :nocov:
  end

end
