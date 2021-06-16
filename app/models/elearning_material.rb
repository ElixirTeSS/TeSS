require 'rails/html/sanitizer'

class ElearningMaterial < Material
  def self.alias
    return "Material"  
  end
  def self.filter
    return {"resource_type"=>"e-learning"}
  end
end
