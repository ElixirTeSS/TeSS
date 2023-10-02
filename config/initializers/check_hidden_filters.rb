# frozen-string-literal: true

Rails.configuration.after_initialize do
  # check the filter lists for correctness
  if TeSS::Config.solr_enabled && TeSS::Config.solr_facets.present?
    TeSS::Config.solr_facets.each_pair do |name, keys|
      unknown_facets = Set.new(keys) - name.classify.constantize.facet_keys

      raise "unknown facets defined for #{name}: #{unknown_facets}" if unknown_facets.any?
    end
  end
end
