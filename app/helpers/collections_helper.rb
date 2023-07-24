# The helper for Collections classes
module CollectionsHelper

  COLLECTIONS_INFO = "Collections can be thought of as folders in which users may collect particular training materials or " +
    "events, from the full catalogue available within #{TeSS::Config.site['title_short']}, " +
    "to address their specific training needs."


  def item_fields(item_class)
    case item_class.name
    when "Event"
      %i[title organizer event_types start country city eligibility created_at]
    when "Material"
      %i[title target_audience status created_at]
    else
      []
    end
  end

  def item_order_badge(collection_item)
    content_tag(:div, collection_item.order, class: 'collection-item-order-badge')
  end

  def item_comment(collection_item)
    content_tag(:blockquote, collection_item.comment, class: 'collection-item-comment')
  end
end
