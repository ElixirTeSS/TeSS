module InSpace
  extend ActiveSupport::Concern

  included do
    belongs_to :space, optional: true

    if TeSS::Config.solr_enabled
      searchable do
        integer :space_id
      end
    end
  end

  def space= s
    return if s.default?
    super
  end

  class_methods do
    def in_current_space
      Space.current_space&.default? ? all : where(space_id: Space.current_space&.id)
    end
  end
end
