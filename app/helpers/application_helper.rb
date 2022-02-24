require 'i18n_data'

# The core application helper
module ApplicationHelper
  # def bootstrap_class_for flash_type
  #   { success: "alert-success", error: "alert-danger", alert: "alert-warning", notice: "alert-info" }[flash_type] || flash_type.to_s
  # end

  BOOTSTRAP_FLASH_MSG = {
    success: 'alert-success',
    error: 'alert-danger',
    alert: 'alert-warning',
    notice: 'alert-success',
    warning: 'alert-warning',
    info: 'alert-info'
  }.freeze

  ICONS = {
    started: { icon: 'fa-hourglass-half', message: 'This event has already started' },
    expired: { icon: 'fa-hourglass-end', message: 'This event has finished' },
    online: { icon: 'fa-desktop', message: 'This is an online event' },
    face_to_face: { icon: 'fa-users', message: 'This is a physical event' },
    scraped_today: { icon: 'fa-check-circle-o', message: 'This record was updated today' },
    not_scraped_recently: { icon: 'fa-exclamation-circle', message: 'This record has not been updated since %SUB%' },
    event: { icon: 'fa-calendar', message: 'This is a training event' },
    material: { icon: 'fa-book', message: 'This is a training material' },
    suggestion: { icon: 'fa-commenting-o', message: 'This record has one or more suggested scientific topics' },
    private: { icon: 'fa-eye-slash', message: 'This resource is private' },
    missing: { icon: 'fa-chain-broken', message: 'This resource has been offline for over three days' }
  }.freeze

  def scrape_status_icon(record, size = nil)
    if !record.last_scraped.nil? && record.scraper_record
      if record.stale?
        message = ICONS[:not_scraped_recently][:message].gsub(/%SUB%/, record.last_scraped.to_s)
        return "<span class='stale-icon pull-right'>#{icon_for(:not_scraped_recently, size, message: message)}</span>".html_safe
      else
        return "<span class='fresh-icon pull-right'>#{icon_for(:scraped_today, size)}</span>".html_safe
      end
    end
    nil
  end

  def missing_icon(record, size = nil)
    if record.failing?
      return "<span class='missing-icon pull-right'>#{icon_for(:missing, size)}</span>".html_safe
    end
    nil
  end

  def hide_failing(record)
    if current_user && current_user.is_admin?
      return false
    else
      if record.failing?
        return true
      end
    end
    false
  end

  def suggestion_icon(record, size = nil)
    if record.edit_suggestion
      return "<span class='fresh-icon pull-right' style='padding-right: 10px;'>#{icon_for(:suggestion, size)}</span>".html_safe
    end
  end

  def icon_for(type, size = nil, options = {})
    options[:class] ||= "info-icon#{'-' + size.to_s if size}"
    "<i class=\"fa #{ICONS[type][:icon]} has-tooltip #{options[:class]}\"
    aria-hidden=\"true\"
    data-toggle=\"tooltip\"
    data-placement=\"auto\"
    title=\"#{options[:message] || ICONS[type][:message]}\">
    </i>".html_safe
  end

  def tooltip_titles(event)
    titles = []
    types = [:started, :expired, :online]
    types.each do |t|
      titles << "#{ICONS[t][:message]}." if event.send("#{t}?")
    end

    if event.stale?
      titles << "#{ICONS[:not_scraped_recently][:message].gsub(/%SUB%/, event.last_scraped.to_s)}."
    else
      titles << "#{ICONS[:scraped_today][:message]}."
    end

    titles.join(' &#13;').html_safe
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

  def render_markdown(markdown_text, options = {}, renderer_options = {})
    if markdown_text
      options.reverse_merge!(filter_html: true, tables: true, autolink: true)
      renderer_options.reverse_merge!(hard_wrap: true, link_attributes: { target: '_blank' })
      Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(renderer_options), options).render(markdown_text).html_safe
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
    'ContentProvider' => TeSS::Config.placeholder['provider'],
    'Package' => TeSS::Config.placeholder['package'],
    'Trainer' => TeSS::Config.placeholder['person'],
    'Node' => 'elixir_logo_orange.png'
  }.freeze

  def get_image_url_for(resource)
    if resource.is_a?(Node) && File.exist?("#{Rails.root}/app/assets/images/nodes/logos/#{resource.country_code}.png")
      "nodes/logos/#{resource.country_code}.png"
    elsif !resource.respond_to?(:image?) || !resource.image?
      DEFAULT_IMAGE_FOR_MODEL.fetch(resource.class.name, TeSS::Config.placeholder['group'])
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
    when 'trainers'
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

  def datetime_picker(form, field, options)
    #puts "datetime_picker options: #{options.to_s}"
    content_tag(:div, class: 'input-group date', data: { datetimepicker: true }) do
      content_tag(:span, class: 'input-group-addon', title: 'Click to display calendar') do
        content_tag(:i, '', class: 'glyphicon glyphicon-calendar')
      end +
        form.text_field(field, class: 'form-control', title: options[:title])
    end
  end

  def date_picker(form, field, options)
    #puts "date_picker options: #{options.to_s}"
    content_tag(:div, class: 'input-group date', data: { datepicker: true }) do
      content_tag(:span, class: 'input-group-addon', title: 'Click to display calendar') do
        content_tag(:i, '', class: 'glyphicon glyphicon-calendar')
      end +
        form.text_field(field, class: 'form-control', title: options[:title])
    end
  end

  # Format an AR collection, or array, into an array of pairs that the common/dropdown partial expects
  def format_for_dropdown(collection)
    collection.map { |o| [o.title, o.id, o.description] }
  end

  def title_with_privacy(resource)
    html = resource.title
    html += " #{icon_for(:private, nil, class: 'muted')}" unless resource.public

    html.html_safe
  end

  ActionView::Helpers::FormBuilder.class_eval do
    def markdown_area(name, options = {})
      text_area(name, options) +
        @template.content_tag(:p, class: 'help-block text-right') do
          @template.image_tag('markdown_logo.png', width: 18) +
            ' This field supports markdown, ' +
            @template.link_to('click here for a reference on markdown syntax.',
                              'https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet', target: '_blank')
        end
    end

    def field_lock(name, options = {})
      field_name = "#{object.class.name.downcase}[locked_fields][]"
      field_id = "#{object.class.name.downcase}_locked_fields_#{name}"
      @template.check_box_tag(field_name, name.to_s, object.field_locked?(name), id: field_id, class: 'field-lock') +
        @template.label_tag(field_id, '', title: 'Lock this field to prevent it being overwritten when automated scrapers are run')
    end

    def tree(name, options = {})
      # TODO: set existing
      existing = { }
      @template.render(partial: 'common/tree', locals: { field_name: name, f: self,
                                                         model_name: options[:model_name],
                                                         resource: object,
                                                         existing: existing,
                                                         field_label: options[:label],
                                                         required: options[:required],
                                                         errors: options[:errors],
                                                         title: options[:title] })

    end

    def dropdown(name, options = {})
      existing_values = object.send(name.to_sym)
      existing = options[:options].select { |label, value| existing_values.include?(value) }
      @template.render(partial: 'common/dropdown', locals: { field_name: name, f: self,
                                                             model_name: options[:model_name],
                                                             resource: object,
                                                             options: options[:options],
                                                             existing: existing,
                                                             field_label: options[:label],
                                                             required: options[:required],
                                                             errors: options[:errors],
                                                             title: options[:title] })
    end

    def autocompleter(name, options = {})
      url = options[:url] || @template.polymorphic_path(name)
      @template.render(partial: 'common/autocompleter', locals: { field_name: name, f: self, url: url,
                                                                  template: options[:template],
                                                                  id_field: options[:id_field] || :id,
                                                                  label_field: options[:label_field] || :title })
    end

    def internal_resource(name, options = {})
      url = options[:url] || @template.polymorphic_path(name)
      @template.render(partial: 'common/internal_resource', locals: { field_name: name, f: self, url: url,
                                                                      template: options[:template],
                                                                      id_field: options[:id_field] || :id,
                                                                      label_field: options[:label_field] || :title })
    end

    def multi_input(name, options = {})
      suggestions = options[:suggestions] || AutocompleteManager.suggestions_array_for(name.to_s)
      @template.render(partial: 'common/multiple_input', locals: { field_name: name, f: self,
                                                                   model_name: options[:model_name],
                                                                   suggestions: suggestions,
                                                                   disabled: options[:disabled],
                                                                   required: options[:required],
                                                                   label: options[:label],
                                                                   errors: options[:errors],
                                                                   title: options[:title] })
    end
  end

  def schemaorg_field(resource, attribute)
    attributes = resource.send(attribute)
    string = ''
    if attributes
      if attributes.class == Array and not attributes.empty?
        attributes.each do |attr|
          string += content_tag :span, attr, { itemprop: attribute.camelize(:lower), content: attr, class: 'schemaorg-element' }
        end
      else
        string += content_tag :span, attributes, { itemprop: attribute.camelize(:lower), content: attributes, class: 'schemaorg-element' }
      end
    end
    return string
  end

  # Try and get a suitable page title
  def site_title
    if content_for?(:title)
      "#{content_for(:title)} - "
    elsif ['static'].include?(controller_name)
      if action_name == 'home'
        ''
      else
        "#{action_name.humanize} - "
      end
    elsif @breadcrumbs && @breadcrumbs.any?
      "#{@breadcrumbs.last[:name]} - "
    elsif controller_name
      "#{controller_name.humanize} - "
    else
      ''
      #end + "TeSS (Training eSupport System)"
    end + TeSS::Config.site['title']
  end

  # Renders a title on the page (by default in an H2 tag, pass a "tag" option with a symbol to change) as well as
  # setting the page title that appears in the browser tab.
  def page_title(title, opts = {})
    content_for(:title, title)
    tag = opts.delete(:tag) || :h2
    content_tag(tag, title, opts)
  end

  def people_suggestions
    (AutocompleteManager.suggestions_array_for('contributors') +
      AutocompleteManager.suggestions_array_for('authors')).uniq
  end

  def star_button(resource)
    star = current_user.stars.where(resource_id: resource.id, resource_type: resource.class.name).first

    link_to '', '#', class: 'btn btn-default',
            data: { role: 'star-button', starred: !star.nil?, resource: { id: resource.id, type: resource.class.name } }
  end

  def next_about_block(feature_count)
    if feature_count & 1 == 0
      result = "even-about-block"
    else
      result = "odd-about-block"
    end
  end

  def show_active(show, block)
    if show == block
      result = "active"
    else
      result = ""
    end
  end

  def currency_collection(priority)
    priors = []
    others = []
    Money::Currency.table.each do |key, value|
      if !priority.empty? and priority.include?(value[:iso_code])
        priors << [value[:name], value[:iso_code]]
      else
        others << [value[:name], value[:iso_code]]
      end
    end
    return priors + others
  end

  def currency_by_iso_code(iso_code)
    if !iso_code.nil? and !iso_code.blank?
      Money::Currency.table.each do |key, value|
        if value[:iso_code] == iso_code
          return value
        end
      end
    end
  end

  def currency_symbol_by_iso_code(iso_code)
    currency = currency_by_iso_code(iso_code)
    if !currency.nil? and !currency[:symbol].nil?
      return currency[:symbol]
    else
      return ''
    end
  end

  def country_alpha2_by_name(name)
    failed = ''
    return failed if name.nil?

    begin
      if name.length < 4
        # search by alpha2 or alpha3
        code = IsoCountryCodes.find(name)
        if name.casecmp(code.alpha2) == 0 or
          name.casecmp(code.alpha3) == 0
          return code.alpha2
        end
      else
        # search by name
        codes = IsoCountryCodes.search_by_name(name)
        if !codes.nil? and codes.length > 0
          codes.each do |code|
            if !code.nil? and code.name == name
              return code.alpha2
            end
          end
        end
      end
    rescue IsoCountryCodes::UnknownCodeError
      # search failed
      return failed
    end

    # nothing found
    return failed
  end

  def language_options_for_select(priority)
    priors = []
    others = []

    I18nData.languages.each do |lang|
      if lang and !lang.empty?
        value = lang[1]
          key = lang[0]
        #Rails.logger.debug "language: key[#{key}] value[#{value}]"
        if priority and !priority.empty? and priority.include?(key)
          priors << [value,key]
        else
          others << [value,key]
        end
      end
    end

    return priors + others
  end

  def language_label_by_key(key)
    if key and !key.nil?
      I18nData.languages.each do |lang|
        return lang[1] if lang[0] == key
      end
    end
  end

  def get_list_of_user_names
    user_list = []
    User.visible.each do |u|
      u.full_name.blank? ? user_list << [u.username, u.username] : user_list << [u.full_name, u.username]
    end
    user_list.sort_by { |u| u.last }
  end

end


