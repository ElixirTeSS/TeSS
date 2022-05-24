class Ingestor

  def initialize
    super
    @messages = Array.new
    @ingested = 0
    @processed = 0
    @added = 0
    @updated = 0
    @rejected = 0
    @token = ''
  end

  # accessor methods
  attr_reader :messages
  attr_reader :ingested
  attr_reader :processed
  attr_reader :added
  attr_reader :updated
  attr_reader :rejected
  attr_accessor :token

  # methods
  def read (url)
    raise 'Method not yet implemented'
  end

  def write (user, provider)
    raise 'Method not yet implemented'
  end

  def convert_description (input)
    return input if input.nil?
    return input if input == ActionController::Base.helpers.strip_tags(input)
    return ReverseMarkdown.convert(input, tag_border: '').strip
  end

  def process_url(row, header)
    row[header].to_s.lstrip unless row[header].nil?
  end

  def process_description (row, header)
    return nil if row[header].nil?
    desc = row[header]
    desc.gsub!(/""/, '"')
    desc.gsub!(/\A""|""\Z/, '')
    desc.gsub!(/\A"|"\Z/, '')
    convert_description desc
  end

  def process_array (row, header)
    row[header].to_s.lstrip.split(/[;]/).reject(&:empty?).compact unless row[header].nil?
  end

  def get_column(row, header)
    row[header].to_s.lstrip unless row[header].nil?
  end

end
