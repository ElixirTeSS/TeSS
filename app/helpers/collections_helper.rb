# The helper for Collections classes
module CollectionsHelper
  COLLECTIONS_INFO = I18n.t('info.collections.description').freeze

  def collections_info
    format(COLLECTIONS_INFO, site_name: TeSS::Config.site['title_short'])
  end

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
    content_tag(:blockquote, collection_item.comment, class: 'collection-item-comment') unless collection_item&.comment.blank?
  end
end
