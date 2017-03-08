# Inspired by SEEK's breadcrumbs library
# https://github.com/seek4science/seek/blob/02d63e9e483deb466ee9097252446c02b5837916/lib/seek/breadcrumbs.rb

module BreadCrumbs
  extend ActiveSupport::Concern

  private

  # Make sure this is called after the @resource is set!
  def set_breadcrumbs
    #Home
    add_breadcrumb 'Home', root_path

    #Index
    add_index_breadcrumb(controller_name)

    if params[:id]
      resource = eval("@#{controller_name.singularize}") || guess_resource

      add_show_breadcrumb resource if (resource && resource.respond_to?(:new_record?) && !resource.new_record?)

      add_breadcrumb action_name.capitalize.humanize, url_for(resource) unless action_name == 'show'
    elsif action_name != 'index'
      add_breadcrumb action_name.capitalize.humanize, url_for(:controller => controller_name, :action => action_name)
    end
  end

  def add_index_breadcrumb controller_name, breadcrumb_name = nil
    breadcrumb_name ||= controller_name.singularize.humanize.pluralize
    add_breadcrumb breadcrumb_name, url_for(:controller => controller_name, :action => 'index')
  end

  def add_show_breadcrumb resource, breadcrumb_name = nil
    breadcrumb_name ||= if resource.respond_to?(:title)
                          resource.title
                        elsif resource.respond_to?(:name) && resource.name.present?
                          resource.name
                        elsif resource.respond_to?(:username) && resource.username.present?
                          resource.username
                        else
                          resource.id
                        end

    add_breadcrumb breadcrumb_name, url_for(resource)
  end

  def add_breadcrumb(name, url = '', options = {})
    @breadcrumbs ||= []
    @breadcrumbs << { name: name, url: url, options: options }
  end

  def guess_resource
    begin
      klass = controller_name.singularize.camelize.constantize
    rescue NameError
      return nil
    end

    if klass.respond_to?(:find_by_id)
      Rails.logger.warn("WARNING: @#{controller_name.singularize} was not set when rendering the breadcrumbs. " \
                        "Ensure `set_breadcrumbs` is called after @#{controller_name.singularize} is set.")
      klass = klass.friendly if klass.respond_to?(:friendly)
      begin
        klass.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end
  end
end
