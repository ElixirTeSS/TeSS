json.array!(@packages) do |package|
  json.extract! package, :id, :name, :description, :image_url, :public
  json.url package_url(package, format: :json)
end
