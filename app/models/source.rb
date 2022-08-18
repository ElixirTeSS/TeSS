class Source < ApplicationRecord
  include PublicActivity::Model
  include Searchable

  belongs_to :user
  belongs_to :content_provider

  validates :url, :method, :resource_type, presence: true
  validates :url, url: true
  validate :check_method_resource_combo

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      string :sort_title do
        url.downcase
      end
      time :created_at
      time :finished_at
      string :url
      string :method
      string :resource_type
      string :content_provider do
        self.content_provider.try(:title)
      end
      integer :user_id
      boolean :enabled
    end
    # :nocov:
  end

  # For compatibility with views that render arbitrary lists of user-creatable resources (e.g. curation page)
  def title
    "#{content_provider.title}: #{Ingestors::IngestorFactory.get_method_value(method)}"
  end

  def source_params
    permitted = [:created_at, :url, :method, :resource_type, :enabled,
                 :content_provider_id, :token ]
    params.require(:source).permit(permitted)
  end

  def self.facet_fields
    %w( content_provider method resource_type enabled )
  end

  def self.check_exists(source_params)
    given_source = self.new(source_params)
    source = nil

    if given_source.url.present?
      source = self.find_by_url(given_source.url)
    end

    source
  end

  def check_method_resource_combo
    unless Ingestors::IngestorFactory.is_method_valid? method
      errors.add :method, 'invalid method'
    end
    unless Ingestors::IngestorFactory.is_resource_valid? resource_type
      errors.add :resource_type, 'invalid resource type'
    end
    begin
      Ingestors::IngestorFactory.get_ingestor method, resource_type
    rescue Exception => e
      errors.add(:resource_type, 'invalid method and resource type combination')
    end
  end

end
