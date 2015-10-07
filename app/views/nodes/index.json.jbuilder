json.array!(@nodes) do |node|
  json.extract! node, :id, :name, :member_status, :country_code, :home_page, :institutions, :trc, :trc_email, :trc, :staff, :twitter, :carousel_images
  json.url node_url(node, format: :json)
end
