module LearningPathsHelper

  def learning_path_breadcrumb_param(topic_link, topic_item)
    { lp: [topic_link, topic_item].map(&:id).join(':') }
  end

end
