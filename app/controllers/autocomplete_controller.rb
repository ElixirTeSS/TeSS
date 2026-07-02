class AutocompleteController < ApplicationController
  respond_to :json

  def suggestions
    suggestions = AutocompleteSuggestion.where(field: params[:field]).query(params[:query])
    respond_with({ suggestions: suggestions })
  end

  def people_suggestions
    people = Person.query(params[:query], 20)
    profiles = Profile.query(params[:query], 20)
    unique_map = {}
    people.each do |p|
      unique_map[p.profile_id || p.orcid || p.name] =
        { value: p.name,
          data: {
            orcid: p.orcid,
            profile_id: p.profile_id
          }
        }
    end
    profiles.each do |p|
      orcid = p.orcid_authenticated? ? p.orcid : nil
      unique_map.delete(orcid) if orcid
      unique_map[p.id] =
        { value: p.full_name,
          data: {
            orcid: orcid,
            profile_id: p.id
          }
        }
    end

    suggestions = unique_map.values.sort_by { |s| [s[:value].downcase, s[:data][:orcid] || 'z'] }
    respond_with({ suggestions: suggestions })
  end
end
