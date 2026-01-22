module LearningPathsHelper

  def learning_path_breadcrumb_param(topic_link, topic_item)
    { lp: [topic_link, topic_item].map(&:id).join(':') }
  end

  def learning_paths_info
    I18n.t('info.learning_paths.description',
           link: I18n.t('info.learning_paths.link'),
           url: registering_learning_paths_path(anchor: 'register_paths'))
  end

  def learning_path_topics_info
    I18n.t('info.learning_path_topics.description',
           link: I18n.t('info.learning_path_topics.link'),
           url: registering_learning_paths_path(anchor: 'topics'))
  end

end
