class Ingestor

  def initialize
    super
    @messages = Array.new
    @ingested = 0
    @processed = 0
    @added = 0
    @updated = 0
    @rejected = 0
  end

  # accessor methods
  attr_reader :messages
  attr_reader :ingested
  attr_reader :processed
  attr_reader :added
  attr_reader :updated
  attr_reader :rejected

  # methods
  def read (url)
    raise 'Method not yet implemented'
  end

  def write (user, provider)
    raise 'Method not yet implemented'
  end

  def convert_description (input)
    stripped = ActionController::Base.helpers.strip_tags(result)
    converted = ReverseMarkdown.convert(result)
    stripped != input ? result = converted : result = input
    result = result.gsub( /\\n/ ,'<br />')
    return result
  end

end