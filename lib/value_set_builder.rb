## FhirGenBuilder contains spec specific code for extracting structures into yaml files for use by Faker

require 'pry'
require 'yaml'
require 'json'

# TODO: Delete this! Once we are using infernos code to get valuesets and other resources, this should be deprecated

# A general purpose valueset extractor would be a useful addition to this application. #self.look_for_other_igs is a starting point.
module FhirGenBuilder
  
  class ValueSetBuilder
    
    # Uses the large "valuesets.json" file that comes with r4 download and splits them into single files for each Value Set.
    def self.add_r4_to_faker source_file: "data/r4/valuesets.json", out_dir: "faker/locales/r4/value_sets/"
      
      json_data = JSON.parse(File.read(source_file))
      json_data["entry"].each do |entry|
        name = entry["fullUrl"].split("/").last
        type = entry.dig("resource", "resourceType")
        
        next unless type == "CodeSystem" or type == "ValueSet"
        
        resource = entry.dig("resource")
        options = { 'en' => { 'faker' => { 'name' => {} }}}
        filename = name + ".yml"

        if type == "CodeSystem"
          option_data = resource.dig("concept")
          if option_data.nil?
            option_data = resource.dig("property")
          end

        elsif type == "ValueSet"
          option_data = resource.dig("compose", "include")[0]["concept"]
        end

        next if option_data.nil?
        options['en']['faker']['name'][self.underscore(name)] = option_data.map do |od|
          od["code"]
        end

        File.open("#{out_dir}#{filename}", "w+") { |f| f.write(options.to_yaml) }
      end
    end

    # Only tested to extract valuesets from us-core files
    def self.look_for_other_igs out_dir:  "faker/locales/package/"
      files = Dir.glob "data/**/ValueSet*"
      files.each do |file|
        json_data = JSON.parse(File.read(file))
        value_set_url = json_data.dig("url")
        next if value_set_url.nil?
        
        options = { 'en' => { 'faker' => { 'name' => {} }}}
        name = value_set_url.split("/").last
        filename = name + ".yml"
        options['en']['faker']['name'][self.underscore(name)] = []

        json_data.dig("compose", "include").each do |subset|
          break if subset["concept"].nil?
          subset["concept"].each do |option_data|
            options['en']['faker']['name'][self.underscore(name)] << option_data["code"]
          end
        end

        if options.any?
          File.open("#{out_dir}#{filename}", "w+") { |f| f.write(options.to_yaml) }
        end

      end
    end

    def self.underscore(str)
      str = str.gsub(/::/, '/').
                gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
                gsub(/([a-z\d])([A-Z])/,'\1_\2').
                tr("-", "_").
                downcase
    end


  end
end

FhirGenBuilder::ValueSetBuilder.add_r4_to_faker
# FhirGenBuilder::ValueSetBuilder.look_for_other_igs