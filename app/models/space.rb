class Space
  include ActiveModel::Model

  attr_accessor :id, :name, :logo

  def self.find(id)
    return nil if id.nil?
    if TeSS::Config.spaces&.key?(id)
      self.new(TeSS::Config.spaces[id].merge(id: id))
    end
  end
end
