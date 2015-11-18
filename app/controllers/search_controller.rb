class SearchController < ApplicationController

  @@search_models = %w(Material User) #Profile
  # GET /searches
  # GET /searches.json
  def index 
    @results = {}
    @@search_models.each do |model|
       begin
           @results[symbolize model] = model.constantize.search {fulltext search_params}
       rescue
         puts "Error finding results for #{model}"
       end 
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.

    def symbolize symbol
       return symbol.downcase.pluralize.to_sym
    end

    def search_params
      params[:q]
    end
end
