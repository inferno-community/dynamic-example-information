## FhirGenBuilder contains spec specific code for extracting structures into yaml files for use by Faker

require 'pry'
require 'yaml'
require 'json'

# TODO: Delete this! Once we are using infernos code to get valuesets and other resources, this should be deprecated
module FhirGenBuilder
  
  class ProfileType

    def self.extract_r4_complex_types source_file: "lib/data/r4/profiles-types.json", out_dir: "lib/extracts/complex_types/"
      json_data = JSON.parse(File.read(source_file))
      json_data["entry"].each do |entry|
        type = entry.dig("resource", "kind")
        next if type != "complex-type"
        name = entry.dig("resource", "id")
        File.open("#{out_dir}#{name}.json", "w+") do |f|
          f.print entry.to_json
        end

        # snapshot_elements = entry.dig("resource", "snapshot", "element")
      end
    end

  end
end