class WidgetLog < ApplicationRecord

  belongs_to :resource, polymorphic: true

end
