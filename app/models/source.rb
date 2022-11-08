class Source < ApplicationRecord
  include PublicActivity::Model
  include Searchable

  belongs_to :user
  belongs_to :content_provider

  validates :url, :method, presence: true
  validates :url, url: true
  validate :check_method

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      string :sort_title do
        url.downcase
      end
      time :created_at
      time :finished_at
      string :url
      string :ingestor_title
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
    "#{content_provider.title}: #{ingestor_title}"
  end

  def ingestor_title
    ingestor_class.config[:title]
  end

  def ingestor_class
    Ingestors::IngestorFactory.get_ingestor(method)
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

  def check_method
    if ingestor_class.nil?
      errors.add :method, 'invalid method'
    end
  end
end
