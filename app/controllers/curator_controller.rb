class CuratorController < ApplicationController
  CURATION_ACTIONS = %w(material.add_topic event.add_topic material.reject_topic event.reject_topic)

  before_action :set_breadcrumbs, :only => [:topic_suggestions]


  # Hacky stub to make breadcrumbs work
  def index
   redirect_to '/curate/topic_suggestions'
  end

  def topic_suggestions
    @suggestions = EditSuggestion.all
    @leaderboard = {}
    CURATION_ACTIONS.each do |curator_action|
      action_count = action_count_for(curator_action)
      action_count.each do |user, count|
        if user
          if @leaderboard[user].nil?
            @leaderboard[user] = {curator_action => count}
          else
            @leaderboard[user].merge!(curator_action => count)
          end
        end
      end
    end
    @leaderboard.each{|user, values| @leaderboard[user]['total'] = values.values.inject(0){|sum,x| sum + x }}
    @leaderboard = @leaderboard.sort_by{|x, y| -y['total']}.first(5)

    respond_to do |format|
      format.html
    end
  end

  private

  def action_count_for(action)
    return PublicActivity::Activity.where(key: action).group_by{|logs| logs.owner}.sort_by{|user, logs| -logs.count}.map{|user,logs| [user, logs.count]}.to_h
  end
end
