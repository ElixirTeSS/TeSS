class CuratorController < ApplicationController
  def topic_suggestions
    @suggestions = EditSuggestion.all
    respond_to do |format|
      format.html
    end
  end
end