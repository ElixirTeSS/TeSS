class SubscriptionMailer < ApplicationMailer

  include ActionView::Helpers::TextHelper
  helper(SubscriptionsHelper)
  helper(EventsHelper)

  def digest(sub, dig)
    @user = sub.user
    @digest = dig
    @subscription = sub
    @collections = if TeSS::Config.feature['collections']
                     @user.maintained_collections
                   else
                     []
                   end
    resource_type = I18n.t("features.#{@subscription.subscribable_type.underscore.pluralize}.short").downcase
    subs = pluralize(@digest.total_count, "new #{resource_type}")
    subject = "#{TeSS::Config.site['title_short']} #{sub.frequency} digest - #{subs} matching your criteria"
    mail(subject: subject, to: sub.user.email) do |format|
      format.html
      format.text
    end
  end

end
