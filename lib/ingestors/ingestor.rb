class Ingestor

  @events = Array.new
  @materials = Array.new
  @provider = nil
  @user = nil

  def initialize
    @events = []
    @materials = []
  end

  def read (url)
    raise 'Method not yet implemented'
  end

  def write (user,provider)
    raise 'Method not yet implemented'
  end

  def add_event (event)
    @events << event if !event.nil?
  end

  def add_material (material)
    @materails << material if !materail.nil?
  end

end