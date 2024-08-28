# https://github.com/rails/sprockets/blob/main/guides/extending_sprockets.md#supporting-all-versions-of-sprockets-in-processors
class SvgRecolourer
  # Mapping of source colour to destination colour
  MAPPING = {
    '#047EAA' => -> { TeSS::Config.site['icon_primary_color'] }, # proc incase config is not loaded here...
    '#F47D21' => -> { TeSS::Config.site['icon_secondary_color'] },
  }

  # Paths in which SVGs should be recoloured
  PATHS = ['images/modern/icons', 'images/modern/learning_paths']

  def initialize(filename, &block)
    @filename = filename
    @source   = block.call
  end

  def render(context, empty_hash_wtf)
    self.class.run(@filename, @source, context)
  end

  def self.run(filename, source, context)
    return source unless PATHS.any? { |p| filename.include?(p) }
    source.gsub(regexp) do |match|
      mapping[match.downcase] || match # Look for replacement, or do nothing
    end
  end

  def self.mapping
    return @mapping if @mapping && Rails.env.production?
    @mapping = {}
    MAPPING.each do |key, value|
      @mapping[key.downcase] = value.respond_to?(:call) ? value.call : value
    end
    @mapping
  end

  def self.regexp
    return @regex if @regex && Rails.env.production?
    @regex = Regexp.new('(' + mapping.keys.map { |k| Regexp.quote(k) }.join('|') + ')',  Regexp::IGNORECASE)
  end

  def self.call(input)
    filename = input[:filename]
    source   = input[:data]
    context  = input[:environment].context_class.new(input)

    result = run(filename, source, context)
    context.metadata.merge(data: result)
  end
end
