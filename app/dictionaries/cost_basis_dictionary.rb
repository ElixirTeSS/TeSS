# Dictionary of Event Types
class CostBasisDictionary < Dictionary

  DEFAULT_FILE = 'cost_basis.yml'

  private

  def dictionary_filepath
    get_file_path 'cost_basis', DEFAULT_FILE
  end

end
