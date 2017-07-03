relevant_params = @model.send(:facet_params, params).merge(q: params[:q]).reject { |k, v| v.blank? }

json.count @search_results.total
json.url polymorphic_url(@model, relevant_params)
json.params relevant_params