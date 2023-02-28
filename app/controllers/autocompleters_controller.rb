class AutocompletersController < ApplicationController
  respond_to :json

  def suggestions
    respond_with({ suggestions: AutocompleteManager.suggestions(params[:field], params[:query]) })
  end
end
