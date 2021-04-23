require 'pry'

module FhirGen
  require_relative 'structure_definition'
  require_relative 'field_set'
  require_relative 'field'

  def self.run resources: [], example_mode: :max, num_examples: 1, ig_name:
    s, f = 0, 0
    pct = []
    total_examples = resources.size * num_examples

    puts "\n\nGenerating #{total_examples} examples across #{resources.size} #{ig_name} resources using #{example_mode} cardinality strategy...\n\n"

    resources.each do |resource|
      sd = nil
      num_examples.times do |ex_num|
        sd = nil
        sd = FhirGen::StructureDefinition.new source: resource, example_mode:example_mode, example_num: ex_num+1, ig_name: ig_name
        sd.write_example
      end
      puts "#{sd.resource_id} (#{num_examples}/#{num_examples})"
      sd.write_failure_log
      stats = sd.get_stats
      stats.map do |stat|
        s += stats[:successes]
        f += stats[:failures]
        pct << stats[:pct]
      end
    end

    coverage = (s.to_f / (s+f)).round(2) * 100
    puts "=========================="
    puts "Success:"
    puts "#{total_examples} examples can be reviewed in 'examples/#{ig_name}'."
    puts ""
    puts "Attribute Coverage: #{coverage.round(2)}%"
    puts "Attributes that could not be faked can be reviewed in 'log/#{ig_name}'.\n\n"
  end

  def self.run_test resource:
    sd = FhirGen::StructureDefinition.new source: resource, example_mode: :max, num_examples: 1
    sd.write_failure_log
    sd.write_example

    puts sd.get_stats
  end

end
