module Ingestors
  module MaterialIngestion
    include AutoParsing

    def add_material(material)
      provider = material[:content_provider] if material.respond_to?(:[])
      if material.is_a?(Hash)
        c = MaterialsController.new
        c.params = { material: material }
        material = OpenStruct.new(c.send(:material_params))
      end
      material.content_provider = provider if provider
      material = handle_auto_parsing(material)
      material = handle_controlled_vocabulary(material)
      @materials << material unless material.nil?
    end
  end
end
