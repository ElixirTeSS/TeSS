module Ingestors
  module AutoParsing
    def get_mapping(var)
      @auto_parse_cache ||= {}
      json_path = File.join(Rails.root, 'lib', 'ingestors', 'auto_parser_mappings', "#{var.to_s}.json")
      return nil unless File.exist?(json_path)

      mtime = File.mtime(json_path)
      cached = @auto_parse_cache[var]
        if cached && cached[:mtime] == mtime
        mapping = cached[:mapping]
        else
        mapping = JSON.parse(File.read(json_path))
        @auto_parse_cache[var] = { mtime: mtime, mapping: mapping }
      end
      mapping
    end

    def auto_parse(var, description)
      mapping = get_mapping(var)
       
      mapping
        &.select{ |key, val| description&.downcase&.include?(key.to_s.downcase) }
        &.values
        &.uniq
    end

    def handle_auto_parsing(obj)
      TeSS::Config.feature['auto_parse_vars'].each do |var|
        new_val = auto_parse(var, obj.description)
        next if new_val.blank? 

        current_val = obj.send(var) if obj.respond_to?(var)
        if !obj.respond_to?(var) || current_val.blank?
          obj.send("#{var}=", new_val)
        end
      end
      obj
    end

    def handle_controlled_vocabulary(obj)
      TeSS::Config.feature['controlled_vocabulary_vars'].each do |var|
        next unless obj.respond_to?(var)

        mapping = get_mapping(var)
        current_val = obj.send(var).map{|x| x.to_s.downcase}
        next if current_val.blank? || mapping.blank?

        new_val = mapping
                    .filter{ |key, val| current_val.include?(key.to_s.downcase) || current_val.include?(val.to_s.downcase) }
                    .map{ |key, val| val }
                    .uniq
        obj.send("#{var}=", new_val)
      end

      obj
    end
  end
end
