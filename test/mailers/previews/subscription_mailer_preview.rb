# Preview all emails at http://localhost:3000/rails/mailers/subscription_mailer
class SubscriptionMailerPreview < ActionMailer::Preview

  def last_event_digest
    sub = Subscription.where(subscribable_type: 'Event').last
    SubscriptionMailer.digest(sub, sub.digest)
  end

  def last_material_digest
    sub = Subscription.where(subscribable_type: 'Material').last
    SubscriptionMailer.digest(sub, sub.digest)
  end

end
