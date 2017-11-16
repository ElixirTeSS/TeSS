module TopicCuration
  extend ActiveSupport::Concern

  #POST /<resource>/1/add_topic
  def add_topic
    #puts "PARAMS: #{params.inspect}"
    resource = instance_variable_get("@#{controller_name.singularize}")
    #puts "RESOURCE: #{resource.inspect}"
    authorize resource, :update?

    topic = EDAM::Ontology.instance.lookup_by_name(params[:topic])
    log_params = {uri: topic.uri,
                  name: topic.preferred_label}

    resource.edit_suggestion.accept_suggestion(topic)
    resource.create_activity :add_topic,
                             owner: current_user,
                             recipient: resource.user,
                             parameters: log_params
    render nothing: true
  end

  #POST /<resource>/1/reject_topic
  def reject_topic
    resource = instance_variable_get("@#{controller_name.singularize}")
    authorize resource, :update?

    topic = EDAM::Ontology.instance.lookup_by_name(params[:topic])
    log_params = {uri: topic.uri,
                  name: topic.preferred_label}

    resource = instance_variable_get("@#{controller_name.singularize}")
    resource.edit_suggestion.reject_suggestion(topic)
    resource.create_activity :reject_topic,
                             owner: current_user,
                             recipient: resource.user,
                             parameters: log_params
    render nothing: true
  end

  #POST /<resource>/1/add_data
  def add_data
    #puts "PARAMS: #{params.inspect}"
    resource = instance_variable_get("@#{controller_name.singularize}")
    #puts "RESOURCE: #{resource.inspect}"
    authorize resource, :update?

    log_params = {data_field: params[:data_field],
                  data_value: params[:data_value]}

    value = resource.edit_suggestion.data_fields[params[:data_field]]

    resource.edit_suggestion.accept_data(resource, params[:data_field], value)
    resource.create_activity :add_data,
                             owner: current_user,
                             recipient: resource.user,
                             parameters: log_params
    render nothing: true
  end

  #POST /<resource>/1/reject_data
  def reject_data
    resource = instance_variable_get("@#{controller_name.singularize}")
    authorize resource, :update?

    log_params = {data_field: params[:data_field],
                  data_value: params[:data_value]}

    resource.edit_suggestion.reject_data(resource, params[:data_field])
    resource.create_activity :reject_data,
                             owner: current_user,
                             recipient: resource.user,
                             parameters: log_params
    render nothing: true
  end
end
