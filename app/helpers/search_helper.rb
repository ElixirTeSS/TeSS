# frozen_string_literal: true

# The helper for searches
module SearchHelper
  def search_and_facet_params
    params.permit(*@model.search_and_facet_keys)
  end

  def clear_filters_path
    params.to_unsafe_h.except(*@model.search_and_facet_keys, :page)
  end

  def filter_link(name, value, count, html_options = {}, &block)
    parameters = search_and_facet_params
    title ||= (html_options.delete(:title) || truncate(value.to_s, length: 50))

    # if there's already a filter of the same facet type, create/add to an array
    parameters[name] = if parameters.include?(name) && !html_options.delete(:replace)
                         Array.wrap(parameters[name]) | [value]
                       else
                         value
                       end

    parameters.delete('page') # remove the page option if it exists
    html_options.reverse_merge!(title: value.to_s)

    link_to parameters, html_options do
      if block_given?
        block.call
      else
        content_tag(:span, title, class: 'facet-label') + content_tag(:span, count.to_s, class: 'facet-count')
      end
    end
  end

  def remove_filter_link(name, value, html_options = {}, &block)
    parameters = search_and_facet_params
    title ||= (html_options.delete(:title) || truncate(value.to_s, length: 50))

    # delete a filter from an array or delete the whole facet if it is the only one
    if parameters.include?(name)
      if parameters[name].is_a?(Array)
        parameters[name].delete(value)
        # Go back to being just a singleton if only one element left
        parameters[name] = parameters[name].first if parameters[name].one?
      else
        parameters.delete(name)
      end
    end

    parameters.delete('page') # remove the page option if it exists
    html_options.reverse_merge!(title: value.to_s)

    link_to parameters, html_options do
      if block_given?
        block.call
      else
        content_tag(:span, title,
                    class: 'facet-label') + content_tag(:i, '', class: 'remove-facet-icon glyphicon glyphicon-remove')
      end
    end
  end

  def toggle_hidden_facet_link(facet)
    "<span class='toggle-#{facet}' style='font-weight: bold;'>
            Show more #{facet.humanize.pluralize.downcase}</span>
            <i class='glyphicon glyphicon-chevron-down pull-right toggle-#{facet}'></i>
            <span class='toggle-#{facet}' style='font-weight: bold; display: none;'>
            Show fewer #{facet.humanize.pluralize.downcase}</span>
            <i class='glyphicon glyphicon-chevron-up pull-right toggle-#{facet}' style='display: none;'></i>
            ".html_safe
  end
end
