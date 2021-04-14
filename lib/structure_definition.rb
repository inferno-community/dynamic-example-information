require 'pry'
require 'json'

module FhirGen
  class StructureDefinition
    attr_accessor :source, :json_data, :resource_name, :field_set, :example, :mv_log


    # Builds a complex object from an Implementation Guide's structure definition JSON file
    # The JSON file MUST have a 'snapshot' key
    #
    # == Parameters:
    # source::
    #   A Structure Definition json file from an implementation guide.
    #
    # id::
    #   This identifies the rank of the example. Currently always using 1, but if someone wanted "100 patients" then this would increment.
    #
    # == Returns:
    # A FieldSet object
    #
    def initialize source:, example_rank: 1
      @source = source
      @example_rank = example_rank
      @json_data = JSON.parse(File.read(@source))
      @mv_log = []

      # Snapshot Elements seem more complete?
      snapshot = @json_data.dig("snapshot", "element").dup
      @resource_name = @json_data["type"]
      @example = FieldSet.new(name: @resource_name, full_name: @resource_name, snapshot: snapshot, parent: self)
    end

    # Replace this with a delegate if we include ActiveSupport
    # Calls the to_h method on the example Fieldset
    def to_h
      @example.to_h
    end

    # Use this method to make any adjustments to our hash.
    # If we end up deciding to do some post-processing on our final hash, this is the spot
    def write_example
      File.open("examples/#{@example_rank}_#{@resource_name}.json", "w+") do |f|
        f.print JSON.pretty_generate(@example.to_h)
      end
    end

    # Field name is a string representing some field we failed to parse.
    # Queues it up for a single log write after the example creation process is complete
    def queue_for_log field_name:
      @mv_log << field_name
    end

    # Write everyting in the @mv_log list to a file with todays date.
    # Writes one log file per resource, and replaces said file each run.
    def write_mv_log
      puts "\n\nFailed to fake #{@mv_log.uniq.size} values for #{@resource_name}"
      File.open("log/#{Date.today.to_s}_#{@resource_name}_mv.log", "w+") do |f|
        @mv_log.uniq.each { |field_name| f.puts("#{Time.now.to_s}: #{field_name}") }
      end
    end


  end
end
