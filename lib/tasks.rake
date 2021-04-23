require 'pry'
require_relative 'fhir_gen'
require_relative 'profile_type_builder'

namespace :fhir_gen do
  IG_DIR = "lib/data/package"

  # Run FhirGen on a single resource and pry into it
  # Example:
  #   rake fhir_gen:test patient
  task :us_core_test, :resource_name do |task, args|
    file = "#{IG_DIR}/StructureDefinition-us-core-#{args[:resource_name]}.json"
    if File.exist? file
      FhirGen.run resources: [file], ig_name: 'uscore'
    else
      puts "File does not exist: #{file}"
    end
  end

  # Run FhirGen on all of the us core data
  # Example:
  #   rake fhir_gen:run[uscore,2,max]
  # Currently logging is disabled, see FhirGen.run_test for how to add it to FhirGen.run
  task :run, :ig_name, :num_examples, :example_mode do |task, args|
    ig_name = args[:ig_name] || "uscore"
    ig_dir = "lib/data/" + ig_name
    num_examples = args[:num_examples] || 1
    example_mode = args[:example_mode] || :random

    sd_files = Dir.glob "#{ig_dir}/StructureDefinition*"
    FhirGen.run resources: sd_files, num_examples: num_examples.to_i, example_mode: example_mode.to_sym, ig_name: ig_name
  end

  task :extract_r4_complex_types do 
    FhirGenBuilder::ProfileType.extract_r4_complex_types
  end
end
