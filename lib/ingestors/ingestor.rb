class Ingestor

  def initialize
    super
  end

  def read (url)
    raise 'Method not yet implemented'
  end

  def write (user, provider)
    raise 'Method not yet implemented'
  end

  def convert_description (input)
    stripped = ActionController::Base.helpers.strip_tags(input)
    converted = ReverseMarkdown.convert input
    stripped != input ? converted : input
  end

end