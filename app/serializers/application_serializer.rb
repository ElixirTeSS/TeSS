class ApplicationSerializer < ActiveModel::Serializer

  include Pundit

  def pundit_user
    CurrentContext.new(current_user, @request)
  end

  def _meta
    { test: 'testing' }
  end

end