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
  }.freeze

  ICONS = {
    started: { icon: 'fa-hourglass-half', message: 'This event has already started' },
    expired: { icon: 'fa-hourglass-end', message: 'This event has finished' },
    online: { icon: 'fa-desktop', message: 'This is an online event' },
    face_to_face: { icon: 'fa-users', message: 'This is a physical event' },
    for_profit: { icon: 'fa-credit-card', message: 'This event is from a for-profit company' },
    scraped_today: { icon: 'fa-check-circle-o', message: 'This record was updated today' },
    not_scraped_recently: { icon: 'fa-exclamation-circle', message: 'This record has not been updated since %SUB%' },
    event: { icon: 'fa-calendar', message: 'This is a training event' },
    material: { icon: 'fa-book', message: 'This is a training material' },
    suggestion: { icon: 'fa-commenting-o', message: 'This record has one or more suggested scientific topics'}
  }.freeze

  def scrape_status_icon(record, size = nil)
    if !record.last_scraped.nil? && record.scraper_record
      if record.last_scraped < (Time.now - 2.days)
        if record.class.name == 'Event'
          if show_event_icons(record)
            ICONS[:not_scraped_recently][:message].gsub!(/%SUB%/, record.last_scraped.to_s)
            return "<span class='stale-icon pull-right'>#{icon_for(:not_scraped_recently, size)}</span>".html_safe
          end
        else
          ICONS[:not_scraped_recently][:message].gsub!(/%SUB%/, record.last_scraped.to_s)
          return "<span class='stale-icon pull-right'>#{icon_for(:not_scraped_recently, size)}</span>".html_safe
        end
      else
        return "<span class='fresh-icon pull-right'>#{icon_for(:scraped_today, size)}</span>".html_safe
      end
    end
    nil
  end

  def suggestion_icon(record,size = nil)
    if record.edit_suggestion
      return "<span class='fresh-icon pull-right' style='padding-right: 10px;'>#{icon_for(:suggestion,size)}</span>".html_safe
    end
  end

  def icon_for(type, size = nil)
    "<i class=\"fa #{ICONS[type][:icon]} has-tooltip info-icon#{'-' + size.to_s if size}\"
    aria-hidden=\"true\"
    data-toggle=\"tooltip\"
    data-placement=\"auto\"
    title=\"#{ICONS[type][:message]}\">
    </i>".html_safe
  end

  def tooltip_titles(event)
    titles = []
    types = [:started, :expired, :online, :for_profit]
    types.each do |t|
      titles << "#{ICONS[t][:message]}." if event.send("#{t}?")
    end
    if show_event_icons(event)
      if event.last_scraped
        if event.last_scraped < (Time.now - 2.days)
          ICONS[:not_scraped_recently][:message].gsub!(/%SUB%/, event.last_scraped.to_s)
          titles << "#{ICONS[:not_scraped_recently][:message]}."
        end
      else
        titles << "#{ICONS[:scraped_today][:message]}."
      end
    end

    titles.join(' &#13;').html_safe
  end

  # Don't show icons/tooltips for iAnn events.
  # Only show icons/tooltips if there's a logged in user
  def show_event_icons(record)
    if record.content_provider
      if record.content_provider.title.downcase == 'iann'
        return false
      end
    end
    unless current_user and current_user.is_admin?
      return false
    end
    return true
  end

  def bootstrap_class_for(flash_type)
    BOOTSTRAP_FLASH_MSG.fetch(flash_type.to_sym, 'alert-info')
  end

  def flash_messages(_opts = {})
    flash.each do |msg_type, message|
      concat(content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type)} fade in", style: 'font-size: 120%; font-weight: bold;') do
        concat content_tag(:button, '&times;'.html_safe, class: 'close', data: { dismiss: 'alert' }, 'aria-label' => 'close')
        concat message
      end)
    end
    nil
  end

  def render_markdown(markdown_text, options = { filter_html: true, tables: true })
    if markdown_text
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, options)
      markdown.render(markdown_text).html_safe
    else
      ''
    end
  end

  # From twitter-bootstrap-rails gem for less:
  # https://github.com/seyhunak/twitter-bootstrap-rails/blob/master/app/helpers/navbar_helper.rb
  def menu_group(options = {}, &block)
    pull_class = "navbar-#{options[:pull]}" if options[:pull].present?
    content_tag(:ul, class: "nav navbar-nav #{pull_class}", &block)
  end

  def menu_item(name = nil, path = '#', *args, &block)
    path = name || path if block_given?
    options = args.extract_options!
    content_tag :li, class: is_active?(path, options) do
      if block_given?
        link_to path, options, &block
      else
        link_to name, path, options, &block
      end
    end
  end

  def is_active?(path, options = {})
    state = uri_state(path, options)
    'active' if state.in?([:active, :chosen]) || state === true
  end

  # Returns current url or path state (useful for buttons).
  # Example:
  #   # Assume we'r currently at blog/categories/test
  #   uri_state('/blog/categories/test', {})               # :active
  #   uri_state('/blog/categories', {})                    # :chosen
  #   uri_state('/blog/categories/test', {method: delete}) # :inactive
  #   uri_state('/blog/categories/test/3', {})             # :inactive
  def uri_state(uri, options = {})
    return options[:status] if options.key?(:status)

    root_url = request.host_with_port + '/'
    root = uri == '/' || uri == root_url
    request_uri = (uri.start_with?(root_url) ? request.url : request.path)

    if !options[:method].nil? || !options['data-method'].nil?
      :inactive
    elsif uri == request_uri || (options[:root] && (request_uri == '/') || (request_uri == root_url))
      :active
    elsif request_uri.start_with?(uri) && !root
      :chosen
    else
      :inactive
    end
  end
  # End from twitter-bootstrap-rails gem for less

  DEFAULT_IMAGE_FOR_MODEL = {
    'ContentProvider' => 'placeholder-organization.png',
    'Package' => 'placeholder-group.png',
    'Node' => 'elixir_logo_orange.png'
  }.freeze

  def get_image_url_for(resource)
    if resource.is_a?(Node) && File.exist?("#{Rails.root}/app/assets/images/nodes/logos/#{resource.country_code}.png")
      "nodes/logos/#{resource.country_code}.png"
    elsif !resource.respond_to?(:image?) || !resource.image?
      DEFAULT_IMAGE_FOR_MODEL.fetch(resource.class.name, 'placeholder-group.png')
    else
      resource.image.url
    end
  end

  # Return icon classes for model name (could be symbol or string)
  def icon_class_for_model(model)
    case model.to_s
    when 'materials'
      'fa fa-book'
    when 'content_providers'
      'fa fa-building-o'
    when 'activity_logs'
      'fa fa-clock-o'
    when 'events'
      'fa fa-calendar'
    when 'users'
      'fa fa-user'
    when 'workflows'
      'fa fa-sitemap'
    when 'nodes'
      'fa fa-share-alt'
    else
      'fa fa-folder-open'
    end
  end

  def app_version_text
    APP_VERSION.blank? ? '' : APP_VERSION.to_s
  end

  # From http://stackoverflow.com/questions/22787021/rails-4-name-of-current-layout
  def current_layout
    (controller.send :_layout).inspect.split('/').last.gsub(/.html.erb/, '')
  end

  def signup_js
    if request.env['PATH_INFO'] == '/users/sign_up'
      return "<script src='https://www.google.com/recaptcha/api.js'></script>\n"
    end
    return ''
  end

  def twitter_link(username)
    link_to("http://twitter.com/#{username}", target: :_blank) do
      "<i class='fa fa-twitter'></i> @#{username}".html_safe
    end
  end

  def info_button(title, &block)
    button_tag(type: 'button', class: 'btn btn-default has-popover',
               data: { toggle: 'popover', placement: 'bottom', trigger: 'focus',
                       title: title, html: true, content: capture(&block) }) do
      "<i class='fa fa-info-circle'></i> <span class='hidden-xs'>#{title}</span>".html_safe
    end
  end

  def empty_tag(tag_symbol, text, style = nil)
    content_tag tag_symbol, text, class: 'empty', style: style
  end

  def info_box(title, &block)
    content_tag(:div, class: 'info-box') do
      content_tag(:h4, raw('<i class="glyphicon glyphicon-info-sign"></i> ' + title), class: 'info-box-header') +
        content_tag(:div, class: 'info-box-content', &block)
    end
  end

  def collapsible_panel(title, id, &block)
    content_tag(:div, class: 'panel panel-default') do
      content_tag(:div, class: 'panel-heading') do
        content_tag(:h4, class: 'panel-title') do
          link_to("##{id}", 'data-toggle' => 'collapse') do
            (title + ' <i class="fa fa-caret-down" aria-hidden="true"></i>').html_safe
          end
        end
      end +
        content_tag(:div, class: 'panel-collapse collapse', id: id) do
          content_tag(:div, class: 'panel-body', &block)
        end
    end
  end

  def tab(text, icon, href, disabled: { check: false }, active: false, count: nil)
    classes = []
    classes << 'disabled' if disabled[:check]
    classes << 'active' if active
    content_tag(:li, class: classes.join(' ')) do
      options = {}
      if disabled[:check]
        options['title'] = disabled[:message]
        options['data-toggle'] = 'tooltip'
      else
        options['data-toggle'] = 'tab'
      end

      text << " (#{count})" if count

      link_to("##{href}", options) do
        %(<i class="#{icon}" aria-hidden="true"></i> #{text}).html_safe
      end
    end
  end

  def datetime_picker(form, field)
    content_tag(:div, class: 'input-group date', data: { datetimepicker: true }) do
      content_tag(:span, class: 'input-group-addon', title: 'Click to display calendar') do
        content_tag(:i, '', class: 'glyphicon glyphicon-calendar')
      end +
        form.text_field(field, class: 'form-control')
    end
  end

  # Format an AR collection, or array, into an array of pairs that the common/dropdown partial expects
  def format_for_dropdown(collection)
    collection.map { |o| [o.title, o.id] }
  end
end
