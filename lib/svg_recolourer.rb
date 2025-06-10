# https://github.com/rails/sprockets/blob/main/guides/extending_sprockets.md#supporting-all-versions-of-sprockets-in-processors
class SvgRecolourer
  # Mapping of source colour to destination colour key
  MAPPING = {
    '#047eaa' => :primary,
    '#f47d21' => :secondary
  }

  # Configured themes. TODO: Read this from some config
  THEMES = {
    'default' => {
      primary: TeSS::Config.site['icon_primary_color'],
      secondary: TeSS::Config.site['icon_secondary_color']
    },
    'green' => {
      primary: '#529d00',
      secondary: '#829d30'
    },
    'blue' => {
      primary: '#024552',
      secondary: '#00839d'
    },
    'space' => {
      primary: '#260252',
      secondary: '#5c29b1'
    },
    'dark' => {
      primary: '#260252',
      secondary: '#5c29b1'
    }
  }

  REGEXP = Regexp.new('(' + MAPPING.keys.map { |k| Regexp.quote(k) }.join('|') + ')',  Regexp::IGNORECASE)

  def initialize(filename, &block)
    @filename = filename
    @source   = block.call
  end

  def render(context, empty_hash_wtf)
    self.class.run(@filename, @source, context)
  end

  def self.run(filename, source, context)
    match_data = filename.match(/images\/themes\/([^\/]+)\//)
    return source unless match_data
    theme = THEMES[match_data[1]]
    raise "Missing theme #{match_data[1]}" unless theme

    source.gsub(REGEXP) do |match|
      theme[MAPPING[match.downcase]] || match # Look for replacement, or do nothing
    end
  end

  def self.call(input)
    filename = input[:filename]
    source   = input[:data]
    context  = input[:environment].context_class.new(input)

    result = run(filename, source, context)
    context.metadata.merge(data: result)
  end
end
