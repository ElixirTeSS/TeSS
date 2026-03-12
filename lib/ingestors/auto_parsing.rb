module Ingestors
  module AutoParsing
    def auto_parse(var, description)
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
        .select{ |key, val| description&.downcase&.include?(key.to_s.downcase) }
        &.values
        &.uniq
    end
  end
end
