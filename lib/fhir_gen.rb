require 'pry'

module FhirGen
  require_relative 'structure_definition'
  require_relative 'field_set'
  require_relative 'field'

end

# Test code to run a patient

sd = FhirGen::StructureDefinition.new(source: "data/package/StructureDefinition-us-core-patient.json")
pp sd.to_h