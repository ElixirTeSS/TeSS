require 'i18n_data'

# The core application helper
module ApplicationHelper
  IGNORED_FILTERS = %w[user].freeze

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
    scraped_today: { icon: 'fa-check-circle-o', message: 'This record was updated today' },
    not_scraped_recently: { icon: 'fa-exclamation-circle', message: 'This record has not been updated since %SUB%' },
    event: { icon: 'fa-calendar', message: 'This is a training event' },
    material: { icon: 'fa-book', message: 'This is a training material' },
    collection: { icon: 'fa-folder-open', message: 'This is a collection' },
    suggestion: { icon: 'fa-commenting-o', message: 'This record has one or more suggested scientific topics' },
    private: { icon: 'fa-eye-slash', message: 'This resource is private' },
    missing: { icon: 'fa-chain-broken', message: 'This resource has been offline for over three days' },
    check: { icon: 'fa-check', message: 'This resource is enabled' },
    cross: { icon: 'fa-times', message: 'This resource has been disabled' }
  }.freeze

  # Countries that have priority in the country selection menu. Using ISO 3166-1 Alpha2 code.
  PRIORITY_COUNTRIES = []

  # Languages that have priority in the trainer language selection menu. Using ISO 639-1 Alpha2 code.
  PRIORITY_LANGUAGES = ['EN']

  # Country timezones that have priority in the timezone selection menu. Using ISO 3166-1 Alpha2 country code.
  PRIORITY_TIME_ZONES = %w[NL GB]

  # Currencies that have priority in the currency selection menu. Using ISO 4217 code.
  PRIORITY_CURRENCIES = %w[EUR GBP]

  def scrape_status_icon(record, size = nil)
    return unless record.respond_to?(:last_scraped)

    return unless !record.last_scraped.nil? && record.scraper_record

    if record.stale?
      message = ICONS[:not_scraped_recently][:message].gsub(/%SUB%/, record.last_scraped.to_s)
      "<span class='stale-icon pull-right'>#{icon_for(:not_scraped_recently, size, message:)}</span>".html_safe
    else
      "<span class='fresh-icon pull-right'>#{icon_for(:scraped_today, size)}</span>".html_safe
    end
  end

  def missing_icon(record, size = nil)
    return unless record.failing?

    "<span class='missing-icon pull-right'>#{icon_for(:missing, size)}</span>".html_safe
  end

  def resource_type_icon(record, size = nil)
    return if record.resource_type.nil?

    "<span class='missing-icon pull-right'>#{icon_for(record.resource_type.to_sym, size)}</span>".html_safe
  end

  def enabled_icon(record, size = nil)
    return if record.nil? or record.enabled.nil?

    if record.enabled
      "<span class='fresh-icon pull-right'>#{icon_for(:check, size)}</span>".html_safe
    else
      "<span class='missing-icon pull-right'>#{icon_for(:cross, size)}</span>".html_safe
    end
  end

  def suggestion_icon(record, size = nil)
    return unless record.edit_suggestion

    "<span class='fresh-icon pull-right'>#{icon_for(:suggestion, size)}</span>".html_safe
  end

  def event_status_icon(event, size = nil)
    if event.started?
      "<span class='event-started-icon pull-right'>#{icon_for(:started, size)}</span>".html_safe
    elsif event.expired?
      "<span class='event-expired-icon pull-right'>#{icon_for(:expired, size)}</span>".html_safe
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

  def bootstrap_class_for(flash_type)
    BOOTSTRAP_FLASH_MSG.fetch(flash_type.to_sym, 'alert-info')
  end

  def flash_messages(_opts = {})
    flash.each do |msg_type, message|
      concat(content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type)} fade in") do
        concat content_tag(:button, '&times;'.html_safe, class: 'close', data: { dismiss: 'alert' }, 'aria-label' => 'close')
        concat message
      end)
    end
    nil
  end

  def render_markdown(markdown_text, options = {}, renderer_options = {})
    if markdown_text
      options.reverse_merge!(filter_html: true, tables: true, autolink: true)
      renderer_options.reverse_merge!(hard_wrap: true, link_attributes: { target: '_blank', rel: 'noopener' })
      Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(renderer_options), options).render(markdown_text).html_safe
    else
      ''
    end
  end

  def render_sanitized_markdown(markdown_text, options = {}, renderer_options = {})
    sanitize(render_markdown(markdown_text, options, renderer_options), tags: %w[strong em b i p br ul ol li])
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
    'active' if state.in?(%i[active chosen]) || state === true
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
    'ContentProvider' => TeSS::Config.placeholder['content_provider'],
    'Collection' => TeSS::Config.placeholder['collection'],
    'Trainer' => TeSS::Config.placeholder['person'],
    'Node' => 'elixir/elixir.svg'
  }.freeze

  def get_image_url_for(resource)
    if resource.is_a?(Node) && File.exist?("#{Rails.root}/app/assets/images/nodes/logos_svg/#{resource.country_code}.svg")
      "nodes/logos_svg/#{resource.country_code}.svg"
    elsif !resource.respond_to?(:image?) || !resource.image?
      DEFAULT_IMAGE_FOR_MODEL.fetch(resource.class.name)
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
    when 'sources'
      'fa fa-cloud-download'
    when 'testing'
      'fa fa-flask'
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
    return "<script src='https://www.google.com/recaptcha/api.js'></script>\n" if request.env['PATH_INFO'] == '/users/sign_up'

    ''
  end

  def twitter_link(username)
    link_to("http://twitter.com/#{username}", target: '_blank', rel: 'noopener') do
      "<i class='fa fa-twitter'></i> @#{username}".html_safe
    end
  end

  def info_button(title, opts = {}, &block)
    classes = 'btn btn-default has-popover'
    classes << " #{opts[:class]}" if opts[:class]
    title_text = opts[:hide_text] ? '' : title
    content_tag(:a, tabindex: 0, class: classes,
                    data: { toggle: 'popover', placement: 'bottom',
                            title:, html: true, content: capture(&block) }) do
      "<i class='icon icon-md information-icon'></i> <span class='hidden-xs'>#{title_text}</span>".html_safe
    end
  end

  def empty_tag(tag_symbol, text, style = nil)
    content_tag tag_symbol, text, class: 'empty', style:
  end

  def info_box(title, &block)
    content_tag(:div, class: 'info-box') do
      content_tag(:div, raw('<i class="glyphicon glyphicon-info-sign"></i> ' + title), class: 'info-box-header') +
        content_tag(:div, class: 'info-box-content', &block)
    end
  end

  def collapsible_panel(title, id, &block)
    content_tag(:div, class: 'panel panel-default collapsible-panel') do
      content_tag(:div, class: 'panel-heading collapsible-panel-link collapsed', 'data-toggle' => 'collapse',
                        'data-target' => "##{id}") do
        content_tag(:div, title, class: 'panel-title')
      end +
        content_tag(:div, class: 'panel-collapse collapse', id:) do
          content_tag(:div, class: 'panel-body', &block)
        end
    end
  end

  def tab(text, icon, href, disabled: { check: false }, active: false, count: nil, activator: nil, options: {})
    classes = []
    classes << 'disabled' if disabled[:check]
    classes << 'active' if active || activator&.check_tab(href, !disabled[:check])
    content_tag(:li, class: classes.join(' ')) do
      if disabled[:check]
        options['title'] = disabled[:message]
        options['data-toggle'] = 'tooltip'
      else
        options['data-toggle'] = 'tab'
        options['data-tab-history'] = true
        options['data-tab-history-changer'] = 'replace'
        options['data-tab-history-update-url'] = true
      end

      text << " (#{count})" if count

      link_to("##{href}", options) do
        %(<i class="#{icon}" aria-hidden="true"></i> #{text}).html_safe
      end
    end
  end

  def datetime_picker(form, field, options)
    # puts "datetime_picker options: #{options.to_s}"
    content_tag(:div, class: 'input-group date', data: { datetimepicker: true }) do
      content_tag(:span, class: 'input-group-addon', title: 'Click to display calendar') do
        content_tag(:i, '', class: 'glyphicon glyphicon-calendar')
      end +
        form.text_field(field, class: 'form-control', title: options[:title])
    end
  end

  def date_picker(form, field, options)
    # puts "date_picker options: #{options.to_s}"
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
        @template.content_tag(:p, class: 'help-block') do
          @template.image_tag('markdown_logo.png', width: 0) +
            'This field supports markdown. Read more on ' +
            @template.link_to('markdown syntax',
                              'https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet', target: '_blank',
                                                                                                  rel: 'noopener')
        end
    end

    def field_lock(name, _options = {})
      field_name = "#{object.class.name.downcase}[locked_fields][]"
      field_id = "#{object.class.name.downcase}_locked_fields_#{name}"
      @template.check_box_tag(field_name, name.to_s, object.field_locked?(name), id: field_id, class: 'field-lock') +
        @template.label_tag(field_id, '', class: 'field-lock-label', title: 'Lock this field to prevent it being overwritten when automated scrapers are run')
    end

    def dropdown(name, options = {})
      existing_values = object.send(name.to_sym)
      existing = options[:options].select { |_label, value| existing_values.include?(value) }
      @template.render(partial: 'common/dropdown', locals: { field_name: name, f: self,
                                                             model_name: options[:model_name],
                                                             resource: object,
                                                             options: options[:options],
                                                             existing:,
                                                             field_label: options[:label],
                                                             required: options[:required],
                                                             errors: options[:errors],
                                                             title: options[:title] })
    end

    def hidden?(name, visibility_toggle)
      visibility_toggle.include?(name.to_s)
    end

    def autocompleter(name, options = {})
      url = options[:url] || @template.polymorphic_path(name)
      visibility_toggle = options[:visibility_toggle] || []
      @template.render(partial: 'common/autocompleter', locals: { field_name: name, f: self, url:,
                                                                  template: options[:template],
                                                                  id_field: options[:id_field] || :id,
                                                                  label_field: options[:label_field] || :title,
                                                                  form_field_name: options[:form_field_name],
                                                                  existing_items_method: options[:existing_items_method],
                                                                  transform_function: options[:transform_function],
                                                                  group_by: options[:group_by],
                                                                  singleton: options[:singleton],
                                                                  hidden: hidden?(name, visibility_toggle) })
    end

    def multi_input(name, options = {})
      options[:suggestions_url] ||= @template.autocomplete_suggestions_path(name) unless options[:suggestions].present?
      visibility_toggle = options[:visibility_toggle] || []
      @template.render(partial: 'common/multiple_input', locals: { field_name: name, f: self,
                                                                   model_name: options[:model_name],
                                                                   suggestions_url: options[:suggestions_url],
                                                                   suggestions: options[:suggestions],
                                                                   disabled: options[:disabled],
                                                                   required: options[:required],
                                                                   label: options[:label],
                                                                   errors: options[:errors],
                                                                   title: options[:title],
                                                                   hint: options[:hint],
                                                                   hidden: hidden?(name, visibility_toggle) })
    end
  end

  def schemaorg_field(resource, attribute)
    attributes = resource.send(attribute)
    string = ''
    if attributes
      if attributes.instance_of?(Array) and !attributes.empty?
        attributes.each do |attr|
          string += content_tag :span, attr, { itemprop: attribute.camelize(:lower), content: attr, class: 'schemaorg-element' }
        end
      else
        string += content_tag :span, attributes, { itemprop: attribute.camelize(:lower), content: attributes, class: 'schemaorg-element' }
      end
    end
    string
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
      # end + "TeSS (Training eSupport System)"
    end + TeSS::Config.site['title']
  end

  # Renders a title on the page (by default in an H2 tag, pass a "tag" option with a symbol to change) as well as
  # setting the page title that appears in the browser tab.
  def page_title(title, opts = {})
    content_for(:title, title)
    tag = opts.delete(:tag) || :h2
    content_tag(tag, title, opts)
  end

  def star_button(resource)
    star = current_user.stars.where(resource_id: resource.id, resource_type: resource.class.name).first

    link_to '', '#', class: 'btn btn-icon',
                     title: "Star this #{resource.class.model_name.human}",
                     data: { role: 'star-button',
                             starred: !star.nil?,
                             resource: { id: resource.id, type: resource.class.name },
                             url: stars_path }
  end

  def external_link_button(text, url, options = {})
    options.reverse_merge!({ class: 'btn btn-primary' })
    text = (text + ' <i class="icon icon-md arrow-top-right-white-icon"></i>').html_safe
    external_link(text, url, options)
  end

  def external_link(text, url, options = {})
    track = options.delete(:track)
    if track
      options.reverse_merge!('data-trackable' => true)
      if track.is_a?(ApplicationRecord)
        options.reverse_merge!('data-trackable-type' => track.class.name)
        options.reverse_merge!('data-trackable-id' => track.id)
      end
    end
    options.reverse_merge!({ rel: 'noopener', target: '_blank' })
    link_to(text, url, options)
  end

  def edit_button(resource, url: nil, text: nil, anchor: nil)
    url ||= polymorphic_path([:edit, resource])
    url += "##{anchor}" if anchor
    text ||= t('.edit', default: t('helpers.links.edit'))
    link_to text, url, class: 'btn btn-default'
  end

  def delete_button(resource, url: nil, text: nil, confirmation: nil)
    url ||= resource
    text ||= t('.destroy', default: t('helpers.links.destroy'))
    confirmation ||= t('.confirm', default: t('helpers.links.confirm', default: 'Are you sure?'))
    link_to text, url, method: 'delete', data: { confirm: confirmation }, class: 'btn btn-danger'
  end

  def next_about_block(feature_count)
    result = if feature_count & 1 == 0
               'even-about-block'
             else
               'odd-about-block'
             end
  end

  def show_active(show, block)
    result = if show == block
               'active'
             else
               ''
             end
  end

  def currency_collection(priority = priority_currencies)
    priors = []
    others = []
    Money::Currency.table.each do |_key, value|
      if !priority.empty? and priority.include?(value[:iso_code])
        priors << [value[:name], value[:iso_code]]
      else
        others << [value[:name], value[:iso_code]]
      end
    end
    priors + others
  end

  def currency_by_iso_code(iso_code)
    return unless !iso_code.nil? and !iso_code.blank?

    Money::Currency.table.each do |_key, value|
      return value if value[:iso_code] == iso_code
    end
  end

  def currency_symbol_by_iso_code(iso_code)
    currency = currency_by_iso_code(iso_code)
    return currency[:symbol] if !currency.nil? and !currency[:symbol].nil?

    ''
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
            return code.alpha2 if !code.nil? and code.name == name
          end
        end
      end
    rescue IsoCountryCodes::UnknownCodeError
      # search failed
      return failed
    end

    # nothing found
    failed
  end

  def language_options_for_select(priority = priority_languages)
    priors = []
    others = []

    I18nData.languages.each do |lang|
      next unless lang and !lang.empty?

      value = lang[1]
      key = lang[0]
      # Rails.logger.debug "language: key[#{key}] value[#{value}]"
      if priority and !priority.empty? and priority.include?(key)
        priors << [value, key]
      else
        others << [value, key]
      end
    end

    priors + others
  end

  def language_label_by_key(key)
    return unless key and !key.nil?

    I18nData.languages.each do |lang|
      return lang[1] if lang[0] == key
    end
  end

  def get_list_of_user_names
    user_list = []
    User.visible.each do |u|
      user_list << (u.full_name.blank? ? [u.username, u.username] : [u.full_name, u.username])
    end
    user_list.sort_by { |u| u.last }
  end

  def providers_path
    content_providers_path
  end

  def priority_countries
    PRIORITY_COUNTRIES
  end

  def priority_languages
    PRIORITY_LANGUAGES
  end

  def priority_time_zones
    PRIORITY_TIME_ZONES.flat_map do |code|
      ActiveSupport::TimeZone.country_zones(code)
    end
  end

  def priority_currencies
    PRIORITY_CURRENCIES
  end

  def about_nav_link(title, path, anchor)
    if current_page?(path)
      link_to(title, "##{anchor}")
    else
      link_to(title, "#{path}##{anchor}")
    end
  end

  def cookie_consent
    CookieConsent.new(cookies.permanent)
  end

  def available_facets(resources)
    if (selected_facets = TeSS::Config.solr_facets&.fetch(controller_name, nil))
      indices = selected_facets.map { |name| resources.facets.index { |f| f.field_name.to_s == name } }.compact
      resources.facets.values_at(*indices)
    else
      resources.facets
    end.select { |f| f.rows.any? && !IGNORED_FILTERS.include?(f.field_name.to_s) }
  end

  class TabActivator
    # An object to determine if a tab/tab-pane should be active.
    def initialize
      @tab_name = nil
    end

    # Returns `true` if the given tab should be active.
    def check_tab(tab_name, condition = true)
      return false unless condition
      return @tab_name == tab_name if @tab_name

      @tab_name = tab_name
      true
    end

    # Returns `true` if the given tab pane should be active.
    def check_pane(tab_name)
      @tab_name == tab_name
    end
  end

  def tab_activator
    TabActivator.new
  end

  def broken_link_notice(resource)
    content_tag('div', t('warnings.link_broken',
                         resource_type: resource.model_name.human.downcase,
                         fail_date: resource.link_monitor.failed_at.strftime(EventsHelper::DATE_STRF)),
                class: 'alert alert-warning mb-4 broken-link-notice')
  end

  def archived_notice(resource)
    content_tag('div', t('warnings.archived', resource_type: resource.model_name.human.downcase),
                class: 'alert alert-warning mb-4 archived-notice')
  end
end
