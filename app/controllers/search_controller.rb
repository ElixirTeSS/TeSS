class SearchController < ApplicationController

  # GET /searches
  # GET /searches.json
  def index 
    @results = {}
    @results[:materials] = Material.search {fulltext search_params}.results
    @results[:users] = User.search { fulltext search_params}.results
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def search_params
      params[:q]
    end
end
