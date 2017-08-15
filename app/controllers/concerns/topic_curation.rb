module TopicCuration
  extend ActiveSupport::Concern

  #POST /<resource>/1/add_topic
  def add_topic
    resource = instance_variable_get("@#{controller_name.singularize}")
    authorize resource, :update?

    topic = EDAM::Ontology.instance.lookup_by_name(params[:topic])
    log_params = {uri: topic.uri,
                  name: topic.preferred_label}

    resource.edit_suggestion.accept_suggestion(resource, topic)
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
end
