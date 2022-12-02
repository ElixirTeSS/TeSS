module Ingestors
  module MaterialIngestion
    def add_material(material)
      material = OpenStruct.new(material) if material.is_a?(Hash)
      @materials << material unless material.nil?
    end
  end
end
