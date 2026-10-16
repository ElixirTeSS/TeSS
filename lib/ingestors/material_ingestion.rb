module Ingestors
  module MaterialIngestion
    include AutoParsing

    def add_material(material)
      if material.is_a?(Hash)
        providers = material[:providers]
        c = MaterialsController.new
        c.params = { material: material }
        material = OpenStruct.new(c.send(:material_params))
        material.providers = providers
      end
      material = handle_auto_parsing(material)
      material = handle_controlled_vocabulary(material)
      @materials << material unless material.nil?
    end
  end
end
