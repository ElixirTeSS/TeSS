json.array!(@packages) do |package|
  json.extract! package, :id, :title, :description, :image_url
  json.url package_url(package, format: :json)
end
