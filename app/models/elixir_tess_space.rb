class ElixirTessSpace < Space
  class Image
    def url
      TeSS::Config.site['logo']
    end
  end

  def image?
    true
  end

  def image
    Image.new
  end

  def host
    'tess.elixir-europe.org'
  end

  def title
    'ELIXIR TeSS'
  end

  def theme
    'default'
  end

  def theme_colour
    '#FFFFFF'
  end

  def model_name
    Space.model_name
  end

  def to_partial_path
    'spaces/space'
  end

  def self.policy_class
    SpacePolicy
  end

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
