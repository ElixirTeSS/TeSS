json.array!(@nodes) do |node|
  json.extract! node, :id, :title, :description, :image_url, :events, :materials, :created_at, :updated_at
  json.url node_url(node, format: :json)
end
