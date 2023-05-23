# frozen_string_literal: true

json.extract! @trainer, :id, :full_name, :website, :orcid,
              :description, :location, :experience, :updated_at, :fields
