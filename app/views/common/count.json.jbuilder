# frozen_string_literal: true

relevant_params = search_and_facet_params.reject { |_k, v| v.blank? }

json.count @search_results.total
json.url polymorphic_url(@model, relevant_params)
json.params relevant_params
