json.array!(@terms) do |term|
  json.extract! term, :uri, :preferred_label, :synonyms
end
