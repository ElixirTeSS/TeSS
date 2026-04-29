class DefaultSpace < GlobalSpace
  def materials
    Material.where(space_id: nil)
  end

  def events
    Event.where(space_id: nil)
  end

  def workflows
    Workflow.where(space_id: nil)
  end

  def collections
    Collection.where(space_id: nil)
  end

  def learning_paths
    LearningPath.where(space_id: nil)
  end

  def learning_path_topics
    LearningPathTopic.where(space_id: nil)
  end
end
