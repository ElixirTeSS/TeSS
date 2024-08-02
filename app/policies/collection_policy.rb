class CollectionPolicy < ResourcePolicy

  def update?
    super || @record.collaborator?(@user)
  end

  def show?
    (!@record.from_unverified_or_rejected? && @record.public?) || manage?
  end

  def curate?
    update?
  end

  def update_curation?
    curate?
  end

  class Scope < Scope
    def resolve
      Collection.visible_by(@user)
    end
  end

end
