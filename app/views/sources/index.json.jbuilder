json.array!(@sources) do |source|
  json.extract! source, :content_provider, :created_at, :url,
                :method, :enabled
  json.url source_url(source)
end
