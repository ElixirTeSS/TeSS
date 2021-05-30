# The helper for searches
module SearchHelper

  def search_and_facet_params
    params.permit(*@model.search_and_facet_keys)
  end

  def filter_link name, value, count, title = nil, html_options={}, &block
    parameters = search_and_facet_params
    title ||= (title || truncate(value.to_s, length: 30))

    #if there's already a filter of the same facet type, create/add to an array
    if parameters.include?(name)
      parameters[name] = Array.wrap(parameters[name]) | [value]
    else
      parameters[name] = value
    end

    parameters.delete('page') #remove the page option if it exists
    html_options.reverse_merge!(title: value.to_s)

    link_to parameters, html_options do
      if block_given?
        yield
      else
        title + content_tag(:span, "#{count}", class: 'facet-count')
      end
    end
  end

  def remove_filter_link name, value, html_options={}, title=nil, &block
    parameters = search_and_facet_params
    title ||= (title || truncate(value.to_s, length: 30))

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
        yield
      else
      "#{title}&nbsp;<i class='glyphicon glyphicon-remove'></i>".html_safe
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

  def neatly_printed_date_range(start, finish = nil)
    return 'No date given' if start.blank? && finish.blank?
    return 'No start date' if !start

    if finish
      out = ''

      strftime_components = []
      if finish.to_date != start.to_date
        strftime_components << '%e'
        if finish.month != start.month
          strftime_components << '%B'
          if finish.year != start.year
            strftime_components << '%Y'
          end
        end
      end

      if strftime_components.any?
        out << "#{start.strftime(strftime_components.join(' '))} - "
      end

      out << "#{finish.strftime('%e %B %Y')}"
    else
      out = start.strftime('%e %B %Y')
    end

    out
  end
end
