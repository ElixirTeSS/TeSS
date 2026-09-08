# The helper for searches
module SearchHelper

  def search_and_facet_params
    params.slice(*@model.search_and_facet_keys, :page_size, :page_number, :page, :per_page).permit!
  end

  def clear_filters_path
    params.to_unsafe_h.except(*@model.search_and_facet_keys, :page)
  end

  def facet_title(name, value, html_options = {})
    lang = render_language_name(value) if name.to_s == 'language'
    return lang unless lang.blank?

    html_options.delete(:title) || truncate(value.to_s, length: 50)
  end

  def filter_link(name, value, count, html_options = {}, &block)
    parameters = search_and_facet_params

    #if there's already a filter of the same facet type, create/add to an array
    if parameters.include?(name) && !html_options.delete(:replace)
      parameters[name] = Array.wrap(parameters[name]) | [value]
    else
      parameters[name] = value
    end

    parameters.delete('page') #remove the page option if it exists
    html_options.reverse_merge!(title: value.to_s)

    content = -> do
      if block_given?
        block.call
      else
        content_tag(:span, facet_title(name, value, html_options), class: 'facet-label') +
          content_tag(:span, "#{count}", class: 'facet-count')
      end
    end

    if filter_limit_reached?
      html_options[:class] = [html_options[:class], 'filter-limit-reached'].compact.join(' ')

      content_tag(:span, html_options, &content)
    else
      link_to parameters, html_options, &content
    end
  end

  def remove_filter_link(name, value, html_options = {}, &block)
    parameters = search_and_facet_params

    #delete a filter from an array or delete the whole facet if it is the only one
    if parameters.include?(name)
      if parameters[name].is_a?(Array)
        parameters[name].delete(value)
        # Go back to being just a singleton if only one element left
        parameters[name] = parameters[name].first if parameters[name].one?
      else
        parameters.delete(name)
      end
    end

    parameters.delete('page') #remove the page option if it exists
    html_options.reverse_merge!(title: value.to_s)

    link_to parameters, html_options do
      if block_given?
        block.call
      else
        content_tag(:span, facet_title(name, value, html_options), class: 'facet-label') +
          content_tag(:i, '', class: 'remove-facet-icon glyphicon glyphicon-remove')
      end
    end
  end

  def toggle_hidden_facet_link facet
    return "<span class='toggle-#{facet}' style='font-weight: bold;'>
            Show more #{facet.humanize.pluralize.downcase}</span>
            <i class='glyphicon glyphicon-chevron-down pull-right toggle-#{facet}'></i>
            <span class='toggle-#{facet}' style='font-weight: bold; display: none;'>
            Show fewer #{facet.humanize.pluralize.downcase}</span>
            <i class='glyphicon glyphicon-chevron-up pull-right toggle-#{facet}' style='display: none;'></i>
            ".html_safe
  end

  def filter_limit_reached?
    current_user.nil? && @facet_params&.values && TeSS::Config.filter_limit &&
      @facet_params.values.flatten.length >= TeSS::Config.filter_limit
  end
end
