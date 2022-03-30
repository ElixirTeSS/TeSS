class CollectionPolicy < ResourcePolicy

  def show?
    @record.public? || manage?
  end

  class Scope < Scope
    def resolve
      Collection.visible_by(@user)
    end
  end

end
