class MaterialPolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      Material.all
    end
  end
end
