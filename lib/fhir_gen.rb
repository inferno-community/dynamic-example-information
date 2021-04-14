require 'pry'

module FhirGen
  require_relative 'structure_definition'
  require_relative 'field_set'
  require_relative 'field'

  def self.run resources: []
    resources.each_with_index do |resource, i|
      puts "Generating example #{i} of #{resources.size}"
      puts "#{resource}...\n"
      FhirGen::StructureDefinition.new source: resource
    end
  end

  def self.run_test resource:
    sd = FhirGen::StructureDefinition.new source: resource
    sd.write_mv_log
    sd.write_example
  end

end

# Use "binding.pry" to debug

# To run this code
# rake fhir_gen:test[patient]

# Test code to run a patient
# sd = FhirGen::StructureDefinition.new(source: "data/package/StructureDefinition-us-core-patient.json")
# pp sd.to_h