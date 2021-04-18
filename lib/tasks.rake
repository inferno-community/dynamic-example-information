require 'pry'
require_relative 'fhir_gen'
require_relative 'profile_type_builder'

namespace :fhir_gen do
  IG_DIR = "lib/data/package"

  # Run FhirGen on a set of named examples
  # Example:
  #   rake fhir_gen:us_core_set patient,condition,practioner
  task :us_core_set, [:names] do |task, args|
    resource_names = args[:names].split(",").map(&:strip)
    resource_names.map! { |rn| "#{IG_DIR}/StructureDefinition-us-core-#{rn}.json" }
    FhirGen.run resources: resource_names
  end

  # Run FhirGen on a single resource and pry into it
  # Example:
  #   rake fhir_gen:test patient
  task :test, [:resource_name] do |task, args|
    file = "#{IG_DIR}/StructureDefinition-us-core-#{args[:resource_name]}.json"
    if File.exist? file
      FhirGen.run_test resource: file
    else
      puts "File does not exist: #{file}"
    end
  end

  # Run FhirGen on all of the us core data
  # Example:
  #   rake fhir_gen:run_all
  # Currently logging is disabled, see FhirGen.run_test for how to add it to FhirGen.run
  task :run_all do |task, args|
    sd_files = Dir.glob("#{IG_DIR}/StructureDefinition*")
    FhirGen.run resources: sd_files
  end
  
  task :extract_r4_complex_types do 
    FhirGenBuilder::ProfileType.extract_r4_complex_types
  end
end
