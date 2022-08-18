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

    if @subscription.save
      flash[:notice] = 'Subscription successfully created.'
      respond_to do |format|
        format.html { redirect_to subscriptions_path }
      end
    else
      flash[:error] = @subscription.errors.full_messages.join(", ")
      respond_to do |format|
        format.html { redirect_to :back }
      end
    end
  end

  def destroy
    authorize @subscription.user, :manage?
    if @subscription.destroy
      flash[:notice] = 'Subscription cancelled.'
      respond_to do |format|
        format.html { redirect_to subscriptions_path }
      end
    else
      respond_to do |format|
        format.html { render plain: 'There was a problem unsubscribing.', status: :unprocessable_entity }
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
        format.html { render plain: 'Invalid code', status: :unprocessable_entity }
      end
    end
  end

  private

  def subscription_params
    subscribable_type = params[:subscription][:subscribable_type].constantize
    p = params.require(:subscription).permit(:frequency, :subscribable_type)
    p.merge(query: params[:q], facets: params.permit(*subscribable_type.facet_fields))
  end

  def find_subscription
    @subscription = Subscription.find(params[:id])
  end

  def set_breadcrumbs
    add_base_breadcrumbs('users')
    @breadcrumbs += [{ name: current_user.name, url: user_path(current_user) }, { name: 'Subscriptions' }]
  end
end
