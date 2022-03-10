require 'ingestors/ingestor_factory'

class Source < ApplicationRecord

  include Searchable

  belongs_to :content_provider
  has_many :results, :dependent => :destroy

  validates :url, url: true

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      string :sort_title do
        url.downcase
      end
      time :created_at
      string :url
      string :method
      string :resource_type
      string :content_provider do
        self.content_provider.try(:title)
      end
    end
    # :nocov:
  end

  validates :created_at, :url, :content_provider, :method, :resource_type, presence: true
  validates :url, url: true
  validate :method, IngestorFactory.is_method_valid?(:method)
  validate :resource_type, IngestorFactory.is_resource_valid?(:resource_type)

  def source_params
    permitted = [:created_at, :url, :method, :resource_type, :content_provider]
    params.require(:source).permit(permitted)
  end

  def self.facet_fields
    %w( content_provider method resource_type )
  end


end
