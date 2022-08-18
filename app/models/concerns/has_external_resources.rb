module HasExternalResources

  extend ActiveSupport::Concern

  included do
    has_many :external_resources, as: :source, dependent: :destroy
    accepts_nested_attributes_for :external_resources, allow_destroy: true
    before_validation :remove_duplicate_external_resources

    if TeSS::Config.solr_enabled
      # :nocov:
      searchable do
        string :tools, multiple: true do
          self.external_resources.select(&:is_tool?).collect(&:title)
        end
        string :standard_database_or_policy, multiple: true do
          self.external_resources.select(&:is_fairsharing?).collect(&:title)
        end
        string :related_resources, multiple: true do
          self.external_resources.select(&:is_generic_external_resource?).collect(&:title)
        end
      end
      # :nocov:
    end
  end

  def remove_duplicate_external_resources
    # New resources have a `nil` created_at, doing this puts them at the end of the array.
    # Sorting them this way means that if there are duplicates, the oldest resource is preserved.
    resources = external_resources.to_a.sort_by { |x| x.created_at || 1.year.from_now }
    (resources - resources.uniq { |r| [r.url, r.title] }).each(&:mark_for_destruction)
  end
end
