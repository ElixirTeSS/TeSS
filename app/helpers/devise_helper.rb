module DeviseHelper
  def devise_error_messages!
    return "" if resource.errors.empty?

    messages = resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join
    sentence = I18n.t("errors.messages.not_saved",
                      count: resource.errors.count,
                      resource: resource.class.model_name.human.downcase)

    html = <<-HTML
    <div id="error_expl" class="panel panel-danger">
      <div class="panel-heading">
      <h3 class="panel-title">#{sentence}</h3>
      </div>
      <div class="panel-body">
      <ul>#{messages}</ul>
      </div>
    </div>
    HTML

    html.html_safe
  end
end