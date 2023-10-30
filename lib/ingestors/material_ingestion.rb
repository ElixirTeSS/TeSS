module Ingestors
  module MaterialIngestion
    def add_material(material)
      material = OpenStruct.new(material.with_indifferent_access.slice(*Material.attribute_names)) if material.is_a?(Hash)
      @materials << material unless material.nil?
    end
  end
end
