# frozen_string_literal: true

# The helper for Collections classes
module CollectionsHelper
  COLLECTIONS_INFO = 'Collections can be thought of as folders in which users may collect particular training materials or ' \
                     "events, from the full catalogue available within #{TeSS::Config.site['title_short']}, " \
                     'to address their specific training needs.'.freeze

  def item_fields(item_class)
    case item_class.name
    when 'Event'
      %i[title organizer event_types start country city eligibility created_at]
    when 'Material'
      %i[title target_audience status created_at]
    else
      []
    end
  end
end
