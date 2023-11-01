module Ingestors
  module MaterialIngestion
    def add_material(material)
      if material.is_a?(Hash)
        c = MaterialsController.new
        c.params = { material: material }
        c.send(:material_params)
        material = OpenStruct.new(c.send(:material_params))
      end
      @materials << material unless material.nil?
    end
  end
end
