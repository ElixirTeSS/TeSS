# Preview all emails at http://localhost:3000/rails/mailers/subscription_mailer
class SubscriptionMailerPreview < ActionMailer::Preview

  def monthly_digest
    SubscriptionMailer.digest(Subscription.last, Subscription.last.digest)
  end

end
