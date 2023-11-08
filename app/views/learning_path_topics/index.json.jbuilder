json.array!(@learning_path_topics) do |learning_path_topic|
  json.extract! learning_path_topic, :id, :title, :description
  json.url learning_path_topic_url(learning_path_topic, format: :json)
end
