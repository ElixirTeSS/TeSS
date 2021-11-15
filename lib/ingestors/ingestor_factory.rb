module Ingestors

  class IngestorFactory
    @@methods = ['csv',]
    @@resources = ['event', 'material',]

    def self.get_ingestor (method, resource)
      Ingestor.new
    end

    def self.is_method_valid? (method)
      @@methods.include? method
    end

    def self.is_resource_valid? (resource)
      @@resources.include? resource
    end

  end

  class Ingestor
    def initialize
      super
    end
  end

end