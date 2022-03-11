require 'ingestors/ingestor_factory'

class Source < ApplicationRecord
  include PublicActivity::Model
  include Searchable

  belongs_to :user
  belongs_to :content_provider
  has_many :results, :dependent => :destroy

  validates :created_at, :method, :resource_type, presence: true
  validates :url, url: true
  validate :check_method_resource_combo

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
      integer :user_id
    end
    # :nocov:
  end

  def source_params
    permitted = [:created_at, :url, :method, :resource_type, :content_provider]
    params.require(:source).permit(permitted)
  end

  def self.facet_fields
    %w( content_provider method resource_type )
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
    puts "method: #{method}, resource_type: #{resource_type}"
    begin
      IngestorFactory.get_ingestor(method, resource_type)
      true
    rescue Exception => e
      errors.add(:resource_type, e.message)
    end
  end

end
