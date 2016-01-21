module ApplicationHelper
  # def bootstrap_class_for flash_type
  #   { success: "alert-success", error: "alert-danger", alert: "alert-warning", notice: "alert-info" }[flash_type] || flash_type.to_s
  # end

  BOOTSTRAP_FLASH_MSG = {
      success: 'alert-success',
      error: 'alert-danger',
      alert: 'alert-warning',
      notice: 'alert-info'
  }

  def bootstrap_class_for(flash_type)
    BOOTSTRAP_FLASH_MSG.fetch(flash_type.to_sym, 'alert-info')
  end

  def flash_messages(opts = {})
    flash.each do |msg_type, message|
      concat(content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type)} fade in") do
        concat content_tag(:button, '&times;'.html_safe, class: "close", data: { dismiss: 'alert' }, "aria-label" => 'close')
        concat message
      end)
    end
    nil
  end

  def render_markdown(markdown_text, options={:filter_html=>true})
    if markdown_text
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, options)
      return markdown.render(markdown_text).html_safe
    else
      return ''
    end
  end
end
