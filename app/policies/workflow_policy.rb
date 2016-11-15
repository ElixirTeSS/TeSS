class WorkflowPolicy < ResourcePolicy

  def update?
    super || @record.collaborator?(@user)
  end

  def show?
    @record.public? || manage?
  end

  class Scope < Scope
    def resolve
      Workflow.visible_by(@user)
      if @user
        if @user.is_admin?
          Workflow
        else
          Workflow.references(:collaborations).includes(:collaborations).
              where('workflows.public = :public OR workflows.user_id = :user OR collaborations.user_id = :user',
                    public: true, user: @user)
        end
      else
        Workflow.where(public: true)
      end
    end
  end

end
