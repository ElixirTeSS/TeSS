# The controller for actions related to the curator model
class CuratorController < ApplicationController
  CURATION_ACTIONS = %w(material.add_term event.add_term material.reject_term event.reject_term material.approval_status_changed event.approval_status_changed).freeze
  CURATABLE_TYPES = {
    'materials' => Material,
    'events'    => Event
  }.freeze

  before_action :check_curator
  before_action :set_breadcrumbs, :only => [:topic_suggestions]

  # Hacky stub to make breadcrumbs work
  def index
   redirect_to '/curate/topic_suggestions'
  end

  def topic_suggestions
    @suggestions = EditSuggestion.all.select { |e| e.suggestible }
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

  def users
    @role = Role.fetch(params[:role]) if current_user.is_admin?
    @role ||= Role.fetch('unverified_user')
    @users = User.with_role(@role)
    max_age = nil
    if params[:max_age]
      begin
        max_age = ActiveSupport::Duration.parse(params[:max_age])
      rescue ArgumentError
      end
    end
    @users = @users.where('users.created_at > ?', max_age.ago) if max_age
    @users = @users.order('created_at DESC')
    if params[:with_content]
      @users = @users.includes(*User::CREATED_RESOURCE_TYPES).with_created_resources
    end

    @users = @users.paginate(page: params[:page], per_page: params[:per_page] || 100)

    respond_to do |format|
      format.html
    end
  end

  def resources
    @status = params[:status].presence || 'requested'
    @type = params[:type].presence || 'all'
    @space_id = params[:space_id].presence
    @user_id = params[:user_id].presence

    # Resolve spaces accessible to current_user
    accessible_space_ids = unless current_user.is_admin?
      admin_space_ids = current_user.space_roles.where(key: 'admin').select(:space_id)
      Space.where(is_private: [false, nil])
          .or(Space.where(id: admin_space_ids))
          .pluck(:id)
    end

    target_classes = @type == 'all' ? CURATABLE_TYPES.values : [CURATABLE_TYPES[@type]].compact

    records = target_classes.flat_map do |klass|
      scope = klass.all
      scope = scope.where(approval_status: klass::APPROVAL_STATUS_CODES[@status.to_sym] || @status) if @status != 'all'
      scope = scope.where(content_provider_id: params[:content_provider_id]) if params[:content_provider_id].present?
      scope = scope.where(user_id: @user_id) if @user_id.present? && klass.reflect_on_association(:user)

      if klass.reflect_on_association(:space)
        # Restrict non-admins to accessible spaces + unassigned (nil) resources
        scope = scope.where(space_id: accessible_space_ids + [nil]) unless current_user.is_admin?

        if @space_id.present?
          scope = if @space_id == 'default' && Space.respond_to?(:default)
                    scope.where(space_id: [Space.default&.id, nil])
                  else
                    scope.where(space_id: @space_id)
                  end
        end
      end

      scope.includes(:user, :content_provider, (:space if klass.reflect_on_association(:space))).to_a
    end

    sorted_records = records.sort_by(&:updated_at).reverse

    page = params[:page] || 1
    per_page = params[:per_page] || 20
    @resources = WillPaginate::Collection.create(page, per_page, sorted_records.size) do |pager|
      pager.replace(sorted_records[pager.offset, pager.per_page] || [])
    end

    respond_to(&:html)
  end

  def bulk_approve
    status = params[:status].presence || 'requested'
    type = params[:type].presence || 'all'
    action = params[:approve_action] # 'approve' or 'reject'
    new_status = action == 'reject' ? 'not_approved' : 'approved'
    user_id = params[:user_id].presence

    target_classes = type == 'all' ? CURATABLE_TYPES.values : [CURATABLE_TYPES[type]].compact

    updated_count = 0
    target_classes.each do |klass|
      scope = klass.all
      scope = scope.where(approval_status: klass::APPROVAL_STATUS_CODES[status.to_sym] || status) if status != 'all'
      scope = scope.where(content_provider_id: params[:content_provider_id]) if params[:content_provider_id].present?
      scope = scope.where(user_id: user_id) if user_id.present? && klass.reflect_on_association(:user)

      if params[:space_id].present? && klass.reflect_on_association(:space)
        scope = if params[:space_id] == 'default' && Space.respond_to?(:default)
                  scope.where(space_id: [Space.default&.id, nil])
                else
                  scope.where(space_id: params[:space_id])
                end
      end

      # Run updates record-by-record to trigger callbacks (logs, public activity, etc.)
      scope.find_each do |resource|
        next unless policy(resource).approve?
        if resource.update(approval_status: new_status)
          updated_count += 1
        end
      end
    end

    redirect_to params[:redirect_to].presence || curate_resources_path,
      notice: "#{updated_count} resource(s) successfully #{new_status.humanize.downcase}."
  end

  private

  def action_count_for(action)
    return PublicActivity::Activity.where(key: action).group_by{|logs| logs.owner}.sort_by{|user, logs| -logs.count}.map{|user,logs| [user, logs.count]}.to_h
  end

  def check_curator
    unless current_user && (current_user.is_admin? || current_user.is_curator?)
      handle_error(:forbidden, 'This page is only visible to curators.')
    end
  end

  def recent_resource_approvals
    keys = CURATABLE_TYPES.values.map { |k| "#{k.name.underscore}.approval_status_changed" }
    PublicActivity::Activity.where(trackable_type: CURATABLE_TYPES.values.map(&:name), key: keys)
                            .order(created_at: :desc)
                            .limit(10)
  end
  helper_method :recent_resource_approvals
end
