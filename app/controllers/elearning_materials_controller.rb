# The controller for actions related to the Elearning Materials model
class ElearningMaterialsController < MaterialsController
  def model_for_controller
    return "Material"
  end
end
