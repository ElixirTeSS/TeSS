require 'ingestors/ingestor'
require 'ingestors/ingestor_csv_event'
require 'ingestors/ingestor_csv_material'


class IngestorFactory
  @@methods = ['csv',]
  @@resources = ['event', 'material',]

  def self.get_ingestor (method, resource)
    if is_method_valid?(method) and is_resource_valid?(resource)
      case [method, resource]
      when ['csv', 'event']
        IngestorCsvEvent.new
      when ['csv', 'material']
        IngestorCsvMaterial.new
      else
        raise "Ingestor not yet implemented for method[#{method}] and resource[#{resource}]"
      end
    else
      raise "Invalid method[#{method}] or resource[#{resource}]"
    end
  end

  def self.is_method_valid? (method)
    @@methods.include? method
  end

  def self.is_resource_valid? (resource)
    @@resources.include? resource
  end

end

