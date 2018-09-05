class ApplicationSerializer < ActiveModel::Serializer

  include Rails.application.routes.url_helpers
  include Pundit

  # def _meta
  #   {}
  # end

  def _links
    { self: polymorphic_path(object) }
  end

  def scientific_topics
    ontology_terms(:scientific_topics)
  end

  def operations
    ontology_terms(:operations)
  end

  def external_resources
    object.external_resources.map do |er|
      { title: er.title,
        url: er.url,
        created_at: er.created_at,
        updated_at: er.updated_at,
        api_url: er.api_url_of_tool,
        type: er.is_tool? ? 'tool' : 'other' }
    end
  end

  private

  def pundit_user
    Pundit::CurrentContext.new(current_user, @request)
  end

  def ontology_terms(type)
    object.send(type).map { |t| { preferred_label: t.preferred_label, uri: t.uri } }
  end

end