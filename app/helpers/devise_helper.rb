# The helper for devise classes
module DeviseHelper
  def devise_error_messages!(title = nil)
    title ||= I18n.t("errors.messages.not_saved",
                      count: resource.errors.count,
                      resource: resource.class.model_name.human.downcase)
    render partial: 'common/error_summary', locals: { title: title, resource: resource } unless resource.errors.empty?
  end
end