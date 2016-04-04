class EventPolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      Event.all
    end
  end
end
