class SubscriptionMailer < ApplicationMailer

  include ActionView::Helpers::TextHelper

  def digest(sub)
    @user = sub.user
    @digest = sub.digest
    @subscription = sub
    subject = "TeSS #{sub.frequency} digest - #{pluralize(@digest.total_count, "new #{@subscription.subscribable_type.downcase}")} matching your criteria"
    mail(subject: subject, to: sub.user.email) do |format|
      format.html
      format.text
    end
  end

end
