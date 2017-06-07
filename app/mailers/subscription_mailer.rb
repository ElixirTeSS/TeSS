class SubscriptionMailer < ApplicationMailer

  def digest(subscription)
    @user = subscription.user
    @digest = subscription.digest
    @subscription = subscription
    mail(to: subscription.user.email) do |format|
      format.html
      format.text
    end
  end

end
