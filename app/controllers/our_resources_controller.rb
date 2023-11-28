# The controller for actions related to the resources pages
class OurResourcesController < ApplicationController

    skip_before_action :authenticate_user!, :authenticate_user_from_token!
    before_action :set_breadcrumbs
    before_action :disable_pagination, only: :index

    def set_breadcrumbs
      @breadcrumbs = []
      add_base_breadcrumbs('our_resources')
    end
    
    def our_resources
    end

    def guides
      set_breadcrumbs
      @breadcrumbs += [{ name: 'Guides', url: guides_path }]
    end

    def pedagogic_support
      set_breadcrumbs
      @breadcrumbs += [{ name: 'Support', url: pedagogic_path }]
    end
    
    def trainer_community
      set_breadcrumbs
      @breadcrumbs += [{ name: 'Community', url: community_path }]
    end

    def fair_training
      set_breadcrumbs
      @breadcrumbs += [{ name: 'FAIR', url: fair_path }]
    end

    
  
  end
  