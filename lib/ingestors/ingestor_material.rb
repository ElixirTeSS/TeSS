require 'ingestors/ingestor'

class IngestorMaterial < Ingestor

  @materials = Array.new

  def initialize
    super
    @materials = []
  end

  def add_material (material)
    @materials << material if !material.nil?
  end

end