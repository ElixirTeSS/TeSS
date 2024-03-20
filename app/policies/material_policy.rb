# frozen_string_literal: true

class MaterialPolicy < ScrapedResourcePolicy
  def clone?
    manage?
  end
end
