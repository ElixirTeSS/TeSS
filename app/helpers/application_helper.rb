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

  # From twitter-bootstrap-rails gem for less:
  # https://github.com/seyhunak/twitter-bootstrap-rails/blob/master/app/helpers/navbar_helper.rb
  def menu_group(options={}, &block)
    pull_class = "navbar-#{options[:pull].to_s}" if options[:pull].present?
    content_tag(:ul, :class => "nav navbar-nav #{pull_class}", &block)
  end

  def menu_item(name=nil, path="#", *args, &block)
    path = name || path if block_given?
    options = args.extract_options!
    content_tag :li, :class => is_active?(path, options) do
      if block_given?
        link_to path, options, &block
      else
        link_to name, path, options, &block
      end
    end
  end

  def is_active?(path, options={})
    state = uri_state(path, options)
    "active" if state.in?([:active, :chosen]) || state === true
  end

  # Returns current url or path state (useful for buttons).
  # Example:
  #   # Assume we'r currently at blog/categories/test
  #   uri_state('/blog/categories/test', {})               # :active
  #   uri_state('/blog/categories', {})                    # :chosen
  #   uri_state('/blog/categories/test', {method: delete}) # :inactive
  #   uri_state('/blog/categories/test/3', {})             # :inactive
  def uri_state(uri, options={})
    return options[:status] if options.key?(:status)

    root_url = request.host_with_port + '/'
    root = uri == '/' || uri == root_url

    request_uri = if uri.start_with?(root_url)
                    request.url
                  else
                    request.path
                  end

    if !options[:method].nil? || !options["data-method"].nil?
      :inactive
    elsif uri == request_uri || (options[:root] && (request_uri == '/') || (request_uri == root_url))
      :active
    else
      if request_uri.start_with?(uri) and not(root)
        :chosen
      else
        :inactive
      end
    end
  end
  # End from twitter-bootstrap-rails gem for less

  DEFAULT_IMAGE_FOR_MODEL = {
      'ContentProvider' => 'placeholder-organization.png',
      'Package' => 'placeholder-group.png'
  }

  def get_image_url_for(resource)
    return resource.blank? ? nil : (resource.image_url.blank? ? DEFAULT_IMAGE_FOR_MODEL.fetch(resource.class.name, 'placeholder-group.png') : resource.image_url)
  end

  # Return icon classes for model name (could be symbol or string)
  def icon_class_for_model(model)
    puts model
    if (model.to_s == 'materials')
      return "fa fa-book"
    elsif (model.to_s == 'content_providers')
      return "fa fa-building-o"
    elsif (model.to_s == 'activity_logs')
      return "fa fa-clock-o"
    elsif (model.to_s == 'events')
      return "fa fa-table"
    elsif (model.to_s == 'users')
      return "fa fa-user"
    elsif (model.to_s == "workflows")
      return "fa fa-sitemap"
    else
      return "fa fa-folder-open"
    end
  end

end
