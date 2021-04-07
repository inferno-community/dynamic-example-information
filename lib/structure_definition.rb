require 'pry'
require 'json'

module FhirGen
  class StructureDefinition
    attr_accessor :source, :json_data, :resource_name, :field_set, :example


    # Builds a complex object from an Implementation Guide's structure definition JSON file
    # The JSON file MUST have a 'differential' key AND a 'snapshot' key
    # TODO: Remove requirement for differential, it is currently only used to name the resource, ex: "Patient"
    #
    # == Parameters:
    # source::
    #   A Structure Definition json file from an implementation guide.
    #
    # == Returns:
    # A FieldSet object
    #
    def initialize source:
      @source = source
      @json_data = JSON.parse(File.read(@source))

      # Differential is incomplete
      differential = @json_data.dig "differential", "element"

      # Snapshot Elements seem more complete?
      snapshot = @json_data.dig "snapshot", "element"
      @resource_details = differential.shift
      @resource_name = @resource_details["id"]
      @example = FieldSet.new(name: @resource_name, full_name: @resource_name, snapshot: snapshot)
    end

    # Replace this with a delegate if we include ActiveSupport
    # Calls the to_h method on the example Fieldset
    def to_h
      @example.to_h
    end

  end
end
