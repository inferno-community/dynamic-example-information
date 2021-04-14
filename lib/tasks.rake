require 'pry'
require_relative 'fhir_gen'

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
  task :run_all do
    puts "You probably shouldn't be doing this"
    return true
    sd_files = Dir.glob("#{IG_DIR}/data/package/StructureDefinition*")
    FhirGen.run resources: sd_files
  end


end