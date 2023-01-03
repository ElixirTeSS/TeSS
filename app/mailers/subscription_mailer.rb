class SubscriptionMailer < ApplicationMailer

  include ActionView::Helpers::TextHelper
  helper(SearchHelper)
  helper(SubscriptionsHelper)

  def digest(sub, dig)
    @user = sub.user
    @digest = dig
    @subscription = sub
    @collections = Collection.left_outer_joins(:collaborators).where(collaborators: { id: @user.id}).or(Collection.where(user_id: @user.id)).distinct
    subs = pluralize(@digest.total_count, "new #{@subscription.subscribable_type.downcase}")
    subject = "#{TeSS::Config.site['title_short']} #{sub.frequency} digest - #{subs} matching your criteria"
    mail(subject: subject, to: sub.user.email) do |format|
      format.html
      format.text
    end
  end

end
