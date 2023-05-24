# frozen_string_literal: true

json.array!(@trainers) do |trainer|
  json.extract! trainer, :id, :full_name, :website, :orcid, :description, :location, :experience
end
