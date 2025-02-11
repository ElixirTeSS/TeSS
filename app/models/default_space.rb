class DefaultSpace
  class Image
    def url
      TeSS::Config.site['logo']
    end
  end

  def id
    nil
  end

  def title
    TeSS::Config.site['title_short']
  end

  def logo_alt
    TeSS::Config.site['logo_alt']
  end

  def theme
    nil
  end

  def image?
    true
  end

  def image
    Image.new
  end

  def materials
    Material.all
  end

  def events
    Event.all
  end

  def workflows
    Workflow.all
  end

  def collections
    Collection.all
  end

  def learning_paths
    LearningPath.all
  end

  def learning_path_topics
    LearningPathTopic.all
  end

  def default?
    true
  end
end
