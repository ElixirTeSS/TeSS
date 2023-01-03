# frozen-string-literal: true

# this file has a name late in the alphabet because it needs to be loaded after
# (at least load_ontologies.rb), since it uses Event, Material and Trainer objects
# which may use these.

# systemwide ignored facet on frontend
IGNORED_FILTERS = %w[user].freeze

# check the filter lists for correctness
if TeSS::Config.solr_enabled
  [Event, Material, Trainer].each do |klass|
    unknown_facets = Set.new(TeSS::Config.solr_facets&.fetch(klass.table_name, [])) - klass.facet_keys

    raise "unknown facets defined for #{klass.name}: #{unknown_facets}" if unknown_facets.any?
  end
end
