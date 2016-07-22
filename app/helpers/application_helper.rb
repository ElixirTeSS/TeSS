module ApplicationHelper
  # def bootstrap_class_for flash_type
  #   { success: "alert-success", error: "alert-danger", alert: "alert-warning", notice: "alert-info" }[flash_type] || flash_type.to_s
  # end

  BOOTSTRAP_FLASH_MSG = {
      success: 'alert-success',
      error: 'alert-danger',
      alert: 'alert-warning',
      notice: 'alert-info',
      warning: 'alert-warning',
      info: 'alert-info'
  }

  def bootstrap_class_for(flash_type)
    BOOTSTRAP_FLASH_MSG.fetch(flash_type.to_sym, 'alert-info')
  end

  def flash_messages(opts = {})
    flash.each do |msg_type, message|
      concat(content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type)} fade in", style: "font-size: 120%; font-weight: bold;") do
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
      'Package' => 'placeholder-group.png',
      'Node' => 'elixir_logo_orange.png'
  }

  def get_image_url_for(resource)
    if resource.blank?
      nil
    else
      if resource.is_a?(Node) && File.exists?("#{(Rails.root.to_s)}/app/assets/images/nodes/logos/#{resource.country_code}.png")
        "nodes/logos/#{resource.country_code}.png"
      else
        if !resouce.respond_to?(:image?) || !resource.image?
          DEFAULT_IMAGE_FOR_MODEL.fetch(resource.class.name, 'placeholder-group.png')
        else
          resource.image.url
        end
      end
    end
  end

  # Return icon classes for model name (could be symbol or string)
  def icon_class_for_model(model)
    if (model.to_s == 'materials')
      return "fa fa-book"
    elsif (model.to_s == 'content_providers')
      return "fa fa-building-o"
    elsif (model.to_s == 'activity_logs')
      return "fa fa-clock-o"
    elsif (model.to_s == 'events')
      return "fa fa-calendar"
    elsif (model.to_s == 'users')
      return "fa fa-user"
    elsif (model.to_s == "workflows")
      return "fa fa-sitemap"
    elsif (model.to_s == "nodes")
      return "fa fa-share-alt"
    else
      return "fa fa-folder-open"
    end
  end

  def app_version_text
    APP_VERSION.blank? ? '' : APP_VERSION.to_s
  end

  # From http://stackoverflow.com/questions/22787021/rails-4-name-of-current-layout
  def current_layout
    (controller.send :_layout).inspect.split("/").last.gsub(/.html.erb/,"")
  end

  # Creates a special user with role 'default_user' that is set
  # as owner of orphaned materials, events, content provider, nodes, etc.
  # in the case when original user/owner is deleted (and we cannot have objects
  # without assigned users)
  def get_default_user
    User.get_default_user
  end

  def twitter_link(username)
    link_to("http://twitter.com/#{username}", target: :_blank) do
      "<i class='fa fa-twitter'></i> @#{username}".html_safe
    end
  end

  def info_button(title, &block)
    button_tag(type: 'button', class: 'btn btn-default has-popover filter-button',
               data: { toggle: 'popover', placement: 'bottom', trigger: 'focus',
                       title: title, html: true, content: capture(&block) }) do
      #content_tag(:i, '', class: 'glyphicon glyphicon-info-sign info-block')
      "<i class='fa fa-info-circle'></i> ".html_safe + title
    end
  end

  def empty_tag (tag_symbol, text, style=nil)
    content_tag tag_symbol, text, :class=>"empty", :style=>style
  end

  def info_box(title, &block)
    content_tag(:div, class: 'info-box') do
      content_tag(:h4, raw('<i class="glyphicon glyphicon-info-sign"></i> ' + title), class: 'info-box-header') +
      content_tag(:div, class: 'info-box-content', &block)
    end
  end

end
