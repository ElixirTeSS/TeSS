module Ingestors
  module MaterialIngestion
    include AutoParsing

    def add_material(material)
      if material.is_a?(Hash)
        c = MaterialsController.new
        c.params = { material: material }
        c.send(:material_params)
        material = OpenStruct.new(c.send(:material_params))
      end
      material = handle_auto_parsing(material)
      material = handle_controlled_vocabulary(material)
      @materials << material unless material.nil?
    end
  end
end
