# Inspired by SEEK's breadcrumbs library
# https://github.com/seek4science/seek/blob/02d63e9e483deb466ee9097252446c02b5837916/lib/seek/breadcrumbs.rbmodule TeSS
  module BreadCrumbs
    def self.included(base)
      base.before_filter :add_breadcrumbs
    end

    def add_breadcrumbs
      #Home
      add_breadcrumb "Home", :root_path
    end

    def add_index_breadcrumb controller_name, breadcrumb_name=nil
      breadcrumb_name ||= "#{controller_name.singularize.humanize.pluralize} Index"
      add_breadcrumb breadcrumb_name, url_for(:controller => controller_name, :action => 'index')
    end

    def add_show_breadcrumb resource, breadcrumb_name=nil
      unless resource.is_a?(ProjectFolder)
        breadcrumb_name ||= "#{resource.respond_to?(:title) ? resource.title : resource.id}"
        add_breadcrumb breadcrumb_name, url_for(:controller => resource.class.name.underscore.pluralize, :action => 'show', :id => resource.id)
      end
    end

    def add_edit_breadcrumb resource, breadcrumb_name=nil
      breadcrumb_name ||= "Edit"
      add_breadcrumb breadcrumb_name, url_for(:controller => resource.class.name.underscore.pluralize, :action => 'edit', :id => resource.id)
    end

  end
end
