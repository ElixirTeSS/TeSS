# The controller for actions related to the Subscriptions model
class SubscriptionsController < ApplicationController

  skip_before_action :authenticate_user!, :authenticate_user_from_token!, only: :unsubscribe
  before_action :authenticate_user!, only: :index
  before_action :find_subscription, only: [:destroy, :unsubscribe]
  before_action :set_breadcrumbs, only: :index

  def index
    @subscriptions = current_user.subscriptions.order('created_at DESC')
  end

  def create
    @subscription = current_user.subscriptions.build(subscription_params)
    @subscription.space = current_space unless current_space.default?

    if @subscription.save
      flash[:notice] = t('subscriptions.created')
      respond_to do |format|
        format.html { redirect_to subscriptions_path }
      end
    else
      flash[:error] = @subscription.errors.full_messages.join(", ")
      respond_to do |format|
        format.html { redirect_back(fallback_location: subscriptions_path) }
      end
    end
  end

  def destroy
    authorize @subscription.user, :manage?
    if @subscription.destroy
      flash[:notice] = t('subscriptions.cancelled')
      respond_to do |format|
        format.html { redirect_to subscriptions_path }
      end
    else
      respond_to do |format|
        format.html { render plain: t('subscriptions.problem_unsubscribing'),
                             status: :unprocessable_entity }
      end
    end
  end

  def unsubscribe
    if @subscription.valid_unsubscribe_code?(params[:code]) && @subscription.destroy
      respond_to do |format|
        format.html
      end
    else
      respond_to do |format|
        format.html { render plain: t('subscriptions.invalid_code'),
                             status: :unprocessable_entity }
      end
    end
  end

  private

  def subscription_params
    permitted_facets = subscribable_type&.facet_fields || []
    facet_params = params.slice(*permitted_facets).permit!
    params.require(:subscription).permit(:frequency, :subscribable_type).merge(query: params.delete(:q), facets: facet_params)
  end

  def subscribable_type
    case params[:subscription][:subscribable_type]
    when 'Event'
      Event
    when 'Material'
      Material
    else
      nil
    end
  end

  def find_subscription
    @subscription = Subscription.find(params[:id])
  end

  def set_breadcrumbs
    add_base_breadcrumbs('users')
    @breadcrumbs += [{ name: current_user.name, url: user_path(current_user) },
                     { name: t('subscriptions.breadcrumb') }]
  end
end
