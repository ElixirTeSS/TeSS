# frozen-string-literal: true

# this file has a name late in the alphabet because it needs to be loaded after
# (at least load_ontologies.rb), since it uses Event, Material and Trainer objects
# which may use these.

# systemwide ignored facet on frontend
IGNORED_FILTERS = %w[user].freeze

# check the filter lists for correctness
if TeSS::Config.solr_enabled && TeSS::Config.solr_facets.present?
  TeSS::Config.solr_facets.each_pair do |name, keys|
    unknown_facets = Set.new(keys) - name.classify.constantize.facet_keys

    raise "unknown facets defined for #{name}: #{unknown_facets}" if unknown_facets.any?
  end
end
