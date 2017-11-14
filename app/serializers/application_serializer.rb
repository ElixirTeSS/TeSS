class ApplicationSerializer < ActiveModel::Serializer

  include Rails.application.routes.url_helpers
  include Pundit

  # def _meta
  #   {}
  # end

  def _links
    { self: polymorphic_path(object) }
  end

  private

  def pundit_user
    CurrentContext.new(current_user, @request)
  end

end