# frozen_string_literal: true

json.extract! @content_provider, :id, :title, :image_url, :description, :url, :created_at, :updated_at, :keywords,
              :contact
