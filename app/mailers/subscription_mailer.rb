class SubscriptionMailer < ApplicationMailer

  include ActionView::Helpers::TextHelper
  add_template_helper(SearchHelper)
  add_template_helper(SubscriptionsHelper)

  def digest(sub, dig)
    @user = sub.user
    @digest = dig
    @subscription = sub
    subs = pluralize(@digest.total_count, "new #{@subscription.subscribable_type.downcase}")
    subject = "#{TeSS::Config.site['title_short']} #{sub.frequency} digest - #{subs} matching your criteria"
    mail(subject: subject, to: sub.user.email) do |format|
      format.html
      format.text
    end
  end

end
