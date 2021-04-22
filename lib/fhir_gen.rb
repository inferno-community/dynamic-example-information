require 'pry'

module FhirGen
  require_relative 'structure_definition'
  require_relative 'field_set'
  require_relative 'field'

  def self.run resources: [], example_mode: :max, num_examples: 1
    s, f = 0, 0
    pct = []

    resources.each_with_index do |resource, i|
      puts "Generating example #{i} of #{resources.size}"
      puts "#{resource}...\n"
      sd = nil
      num_examples.times do |ex_num|
        sd = FhirGen::StructureDefinition.new source: resource, example_mode:example_mode, example_num: ex_num+1
        sd.write_example
      end
      sd.write_failure_log
      stats = sd.get_stats
      stats.map do |stat|
        s += stats[:successes]
        f += stats[:failures]
        pct << stats[:pct]
      end
    end


    coverage = (s.to_f / (s+f)).round(2) * 100

    puts "Coverage: #{coverage.round(2)}%"
  end

  def self.run_test resource:
    sd = FhirGen::StructureDefinition.new source: resource, example_mode: :max, num_examples: 1
    sd.write_failure_log
    sd.write_example

    puts sd.get_stats
  end

end

# Use "binding.pry" to debug

# To run this code
# rake fhir_gen:test[patient]

# Test code to run a patient
# sd = FhirGen::StructureDefinition.new(source: "data/package/StructureDefinition-us-core-patient.json")
# pp sd.to_h