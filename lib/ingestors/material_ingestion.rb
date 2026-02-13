module Ingestors
  module MaterialIngestion
    def add_material(material)
      if material.is_a?(Hash)
        c = MaterialsController.new
        c.params = { material: material }
        c.send(:material_params)
        material = OpenStruct.new(c.send(:material_params))
      end
      TeSS::Config.feature['auto_parse_vars'].each do |var|
        new_val = auto_parse(var, event.description)
        event.send("#{var}=", new_val)
      end
      @materials << material unless material.nil?
    end

    def auto_parse(var, description)
      json_path = File.join(Rails.root, 'lib', 'ingestors', 'auto_parser_mappings', "#{var.to_s}.json")
      res = nil
      if File.exist?(json_path)
        mapping = JSON.parse(File.read(json_path))
        res = mapping
          .select{ |key, val| description.downcase.include?(key.to_s.downcase) }
          .values
          .uniq
      end
      res
    end
  end
end
