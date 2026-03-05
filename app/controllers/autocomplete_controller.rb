class AutocompleteController < ApplicationController
  respond_to :json

  def suggestions
    suggestions = AutocompleteSuggestion.where(field: params[:field]).query(params[:query])
    respond_with({ suggestions: suggestions })
  end

  def people_suggestions
    people = Person.query(params[:query])
    suggestions = people.map do |p|
      { value: p.name,
        data: {
          orcid: p.orcid,
          profile_id: p.profile_id
        }
      }
    end
    respond_with({ suggestions: suggestions })
  end
end
