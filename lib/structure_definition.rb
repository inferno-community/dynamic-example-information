require 'pry'
require 'json'
require 'fileutils'

module FhirGen
  class StructureDefinition
    
    attr_accessor :source, :json_data, :resource_name, :field_set, :example, :mv_log, :snapshot, :failures, :successes, :resource_id

    # Used during cleaning to exclude these attribute types
    TYPE_BLACKLIST = ["Extension", "Reference"]

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
    def initialize source:, example_mode:, example_num:, ig_name:
      @source = source
      @failures, @successes = [], []
      @example_num = example_num
      @ig_name = ig_name

      if File.exist? @source
        @json_data = JSON.parse(File.read(@source))
      else
        puts "FILE NOT FOUND #{@source}"
        return
      end
      snapshot = @json_data.dig("snapshot", "element").dup
      @resource_name = @json_data["type"]
      @resource_id = @json_data["id"]

      # Look for complex data types to add into the snapshot.
      snapshot_with_types = clean_snapshot snapshot

      @example = FieldSet.new(name: @resource_name, 
        full_name: @resource_name, 
        snapshot: snapshot_with_types, 
        example_mode: example_mode,
        parent: self
      )
    end

    def get_stats
      { successes: @successes.uniq.size, 
        failures: @failures.uniq.size, 
        pct:(@successes.uniq.size.to_f / (@failures.uniq.size+@successes.uniq.size))}
    end

    # Returns the original snapshot with any complex data types that were not defined inserted into place
    # Removes nodes that we aren't ready/wanting to handle
    # The process of adding in data type nodes would be better suited to FieldSet, but we were having bugs with parsing the JSON files during the run.
    def clean_snapshot snapshot
      snapshot_dt_clean = false
      until snapshot_dt_clean do
        snapshot_dt_clean, snapshot = replace_complex_datatypes snapshot
      end
      snapshot
    end

    # Every call to this method will only replace a single 'level' of nodes.
    # It is continually called by clean_snapshot until the snapshot is unchanged
    def replace_complex_datatypes snapshot
      new_ss = []
      snapshot_dt_clean = true

      snapshot.each do |node|
        node_name = node["id"]
        next if node["type"].nil?
        node_type = node["type"].first["code"]
        if TYPE_BLACKLIST.include?(node_type) || node_name.include?(":")
          next
        end

        # Snapshot defines the children, leave it be.
        if snapshot.detect { |ss_e| ss_e["id"].start_with?("#{node_name}.") }
          new_ss << node
          next
        end

        fp = "lib/extracts/complex_types/#{node_type}.json"
        if !File.exist?(fp)
          new_ss << node
        else
          snapshot_dt_clean = false
          data_type = JSON.parse(File.read(fp))

          node_idx = 0
          type_nodes = data_type.dig("resource", "snapshot", "element").map do |c_node|
            node_idx+=1
            c_node["type"] = [{"code" => node_type}] if !c_node.has_key?("type")

            if node_idx == 1
              node
            else
              c_node["id"] = "#{node_name}.#{c_node['id'].downcase.split(".").last}"
              c_node
            end
          end
          type_nodes.each { |nss| new_ss << nss }
        end
      end
      [snapshot_dt_clean, new_ss]
    end

    def name
      @resource_name
    end

    # Replace this with a delegate if we include ActiveSupport
    # Calls the to_h method on the example Fieldset
    def to_h
      @example.to_h
    end

    # Use this method to make any adjustments to our hash.
    # If we end up deciding to do some post-processing on our final hash, this is the spot
    def write_example
      results = @example.to_h
      results["resourceType"] = @resource_name

      FileUtils.mkdir_p("examples/#{@ig_name}") unless File.exist?("examples/#{@ig_name}")
      File.open("examples/#{@ig_name}/#{@example_num}_#{@resource_id}.json", "w+") do |f|
        f.print JSON.pretty_generate(results.to_h)
      end
    end

    # Field name is a string representing some field we failed to parse.
    # Queues it up for a single log write after the example creation process is complete
    def add_failure field_name:
      @failures << field_name
    end

    # Field name is a string representing some field we failed to parse.
    # Queues it up for a single log write after the example creation process is complete
    def add_success field_name:
      @successes << field_name
    end

    # Write everyting in the @mv_log list to a file with todays date.
    # Writes one log file per resource, and replaces said file each run.
    def write_failure_log
      Dir.mkdir("log/#{@ig_name}") unless File.exist?("log/#{@ig_name}")
      File.open("log/#{@ig_name}/#{Date.today.to_s}_#{@resource_id}_mv.log", "w+") do |f|
        @failures.uniq.each { |field_name| f.puts("#{Time.now.to_s}: #{field_name}") }
      end
    end


  end
end
