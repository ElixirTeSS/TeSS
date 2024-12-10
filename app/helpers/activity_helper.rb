# The helper for PublicActivity

module ActivityHelper
  def activity_owner(activity)
    if activity.owner
      link_to activity.owner.username, activity.owner
    else
      t('activity.deleted_owner')
    end
  end

  def activity_resource(activity)
    if activity.trackable
      title_field = activity.trackable.is_a?(User) ? :name : :title
      link_to activity.trackable.send(title_field), activity.trackable
    else
      t('activity.deleted_trackable')
    end
  end
end