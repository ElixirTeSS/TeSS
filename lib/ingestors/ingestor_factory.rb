require 'ingestors/ingestor_event_csv'
require 'ingestors/ingestor_event_ical'
require 'ingestors/ingestor_event_rest'
require 'ingestors/ingestor_material_csv'
require 'ingestors/ingestor_material_rest'

class IngestorFactory
  @@methods = { 'csv': 'CSV File', 'ical': 'iCalendars', 'rest': 'REST API' }
  @@resources = { 'event': 'Events', 'material': 'Materials' }

  def self.get_ingestor (method, resource)
    if is_method_valid?(method) and is_resource_valid?(resource)
      case [method, resource]
      when ['csv', 'event']
        IngestorEventCsv.new
      when ['ical', 'event']
        IngestorEventIcal.new
      when ['csv', 'material']
        IngestorMaterialCsv.new
      when ['rest', 'event']
        IngestorEventRest.new
      when ['rest', 'material']
        IngestorMaterialRest.new
      else
        raise "Ingestor not yet implemented for method[#{method}] and resource[#{resource}]"
      end
    else
      raise "Invalid method[#{method}] or resource[#{resource}]"
    end
  end

  def self.is_method_valid? (input)
    @@methods.has_key? input.to_sym
  end

  def self.is_resource_valid? (input)
    @@resources.has_key? input.to_sym
  end

  def self.method_for_select
    @@methods.map do |key, value|
      [value, key, '']
    end
  end

  def self.resources_for_select
    @@resources.map do |key, value|
      [value, key, '']
    end
  end

  def self.get_method_value (input)
    @@methods.fetch input.to_sym
  end

  def self.get_resource_value (input)
    @@resources.fetch input.to_sym
  end

end
