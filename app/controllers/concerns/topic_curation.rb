# The concern for topics
module TopicCuration
  extend ActiveSupport::Concern

  #POST /<resource>/1/add_term
  def add_term
    #puts "PARAMS: #{params.inspect}"
    resource = instance_variable_get("@#{controller_name.singularize}")
    #puts "RESOURCE: #{resource.inspect}"
    authorize resource, :update?

    term = EDAM::Ontology.instance.lookup(params[:uri])
    field = params[:field]

    log_params = { uri: term.uri,
                   field: field,
                   name: term.preferred_label }

    resource.edit_suggestion.accept_suggestion(field, term)
    resource.create_activity :add_term,
                             owner: current_user,
                             recipient: resource.user,
                             parameters: log_params
    head :ok
  end

  #POST /<resource>/1/reject_term
  def reject_term
    resource = instance_variable_get("@#{controller_name.singularize}")
    authorize resource, :update?

    term = EDAM::Ontology.instance.lookup(params[:uri])
    field = params[:field]

    log_params = { uri: term.uri,
                   field: field,
                   name: term.preferred_label }

    resource = instance_variable_get("@#{controller_name.singularize}")
    resource.edit_suggestion.reject_suggestion(field, term)
    resource.create_activity :reject_term,
                             owner: current_user,
                             recipient: resource.user,
                             parameters: log_params
    head :ok
  end

  #POST /<resource>/1/add_data
  def add_data
    #puts "PARAMS: #{params.inspect}"
    resource = instance_variable_get("@#{controller_name.singularize}")
    #puts "RESOURCE: #{resource.inspect}"
    authorize resource, :update?

    log_params = {data_field: params[:data_field],
                  data_value: params[:data_value]}

    resource.edit_suggestion.accept_data(params[:data_field])
    resource.create_activity :add_data,
                             owner: current_user,
                             recipient: resource.user,
                             parameters: log_params
    head :ok
  end

  #POST /<resource>/1/reject_data
  def reject_data
    resource = instance_variable_get("@#{controller_name.singularize}")
    authorize resource, :update?

    log_params = {data_field: params[:data_field],
                  data_value: params[:data_value]}

    resource.edit_suggestion.reject_data(params[:data_field])
    resource.create_activity :reject_data,
                             owner: current_user,
                             recipient: resource.user,
                             parameters: log_params
    head :ok
  end
end
