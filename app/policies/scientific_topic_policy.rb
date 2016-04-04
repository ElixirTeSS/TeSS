class ScientificTopicPolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      ScientificTopic.all
    end
  end
end
