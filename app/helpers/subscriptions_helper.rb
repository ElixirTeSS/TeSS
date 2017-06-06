module SubscriptionsHelper

  def frequency_options_for_select
    options_for_select(Subscription::FREQUENCY.keys.map { |k| [k.humanize, k] })
  end

end
