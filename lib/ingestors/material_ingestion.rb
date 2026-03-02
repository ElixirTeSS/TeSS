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
      TeSS::Config.feature['auto_parse_vars'].each do |var|
        new_val = auto_parse(var, material.description)
        next if new_val.blank? 

        current_val = material.send(var) if material.respond_to?(var)
        if !material.respond_to?(var) || current_val.blank?
          material.send("#{var}=", new_val)
        end
      end
      @materials << material unless material.nil?
    end
  end
end
