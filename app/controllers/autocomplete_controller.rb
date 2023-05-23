# frozen_string_literal: true

class AutocompleteController < ApplicationController
  respond_to :json

  def suggestions
    suggestions = AutocompleteSuggestion.where(field: params[:field]).query(params[:query])
    respond_with({ suggestions: suggestions })
  end

  def people_suggestions
    suggestions = AutocompleteSuggestion.people.query(params[:query])
    respond_with({ suggestions: suggestions })
  end
end
