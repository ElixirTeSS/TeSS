module SubscriptionsHelper

  def frequency_options_for_select
    options_for_select(Subscription::FREQUENCY.map { |k| [k[:key].to_s.humanize, k[:key]] })
  end

  def subscription_results_path(sub)
    polymorphic_path(*subscription_results_options(sub))
  end

  def subscription_results_url(sub)
    polymorphic_url(*subscription_results_options(sub))
  end

  private

  def subscription_results_options(sub)
    max_age = Subscription::FREQUENCY.detect { |f| f[:key] == sub.frequency }.try(:[], :title)
    [sub.subscribable_type.constantize, sub.facets.merge(q: sub.query, max_age: max_age)]
  end

end
