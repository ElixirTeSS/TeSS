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

  def digest_event_title(event)
    if event.end
      title = ''

      strftime_components = []
      if event.end.to_date != event.start.to_date
        strftime_components << '%e'
        if event.end.month != event.start.month
          strftime_components << '%B'
          if event.end.year != event.start.year
            strftime_components << '%Y'
          end
        end
      end

      if strftime_components.any?
        title << "#{event.start.strftime(strftime_components.join(' '))} - "
      end

      title << "#{event.end.strftime('%e %B %Y')}"
    else
      title = event.start.strftime('%e %B %Y')
    end

    if event.city || event.country
      title << " | #{[event.city, event.country].reject(&:blank?).join(', ')}"
    end

    title
  end

  private

  def subscription_results_options(sub)
    max_age = Subscription::FREQUENCY.detect { |f| f[:key] == sub.frequency }.try(:[], :title)
    [sub.subscribable_type.constantize, sub.facets.merge(q: sub.query, max_age: max_age)]
  end

end
