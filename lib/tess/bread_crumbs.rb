# Inspired by SEEK's breadcrumbs library
# https://github.com/seek4science/seek/blob/02d63e9e483deb466ee9097252446c02b5837916/lib/seek/breadcrumbs.rb
module Tess
  module BreadCrumbs

    require 'object'

    def self.included(base)
      base.before_filter :add_breadcrumbs
    end

    def add_breadcrumbs

      #Home
      add_breadcrumb "Home", :root_path

      #Index
      add_index_breadcrumb(controller_name)

      resource = eval("@"+controller_name.singularize) || try_block{controller_name.singularize.camelize.constantize.find_by_id(params[:id])}

      add_show_breadcrumb resource if (resource && resource.respond_to?(:new_record?) && !resource.new_record?)

      unless action_name == 'index' || action_name == 'show'
          if resource.nil?
            url = url_for(:controller => controller_name, :action => action_name)
          else
            url = url_for(:controller => controller_name, :action => action_name, :id => resource.try(:id))
          end
          add_breadcrumb "#{action_name.capitalize.humanize}", url
      end
    end

    def add_index_breadcrumb controller_name, breadcrumb_name=nil
      breadcrumb_name ||= "#{controller_name.singularize.humanize.pluralize}"
      add_breadcrumb breadcrumb_name, url_for(:controller => controller_name, :action => 'index')
    end

    def add_show_breadcrumb resource, breadcrumb_name=nil
        breadcrumb_name ||= "#{resource.respond_to?(:title) ? resource.title : resource.respond_to?(:name) ? resource.name : resource.respond_to?(:username) ? resource.username : resource.id}"
        add_breadcrumb breadcrumb_name,
                       url_for(:controller => resource.class.name.underscore.pluralize,
                               :action => 'show',
                               :id => (resource.try(:username) ?
                                   resource.username : (resource.try(:friendly_id) ? resource.friendly_id : resource.id)))
    end

    def add_edit_breadcrumb resource, breadcrumb_name=nil
      breadcrumb_name ||= "Edit"
      add_breadcrumb breadcrumb_name, url_for(:controller => resource.class.name.underscore.pluralize, :action => 'edit', :id => resource.id)
    end

  end
end
