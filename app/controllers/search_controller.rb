class SearchController < ApplicationController

  include TeSS::BreadCrumbs

  @@search_models = %w(Material User Event Package ContentProvider) #Profile
  # GET /searches
  # GET /searches.json
  def index 
    @results = {}
    @@search_models.each do |model|
       begin
         @results[symbolize model] = Sunspot.search(model.constantize) do
            fulltext search_params
            if model == 'Event'
              with('start').greater_than(Time.zone.now)
            end
          end
       rescue

       end 
    end
    @results.reject!{|k,result| result.total < 1}
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.

    def symbolize symbol
       return symbol.underscore.pluralize.to_sym
    end

    def search_params
      params[:q]
    end
end
