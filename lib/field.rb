require 'date'
require 'pry'
require 'faker'
I18n.load_path += Dir[File.join(File.expand_path(File.dirname(__FILE__)), 'faker/locales/**/', '*.yml')]
I18n.reload!

module FhirGen
  class Field

    attr_accessor :name, :full_name, :data, :value, :type, :value_set

    # Represents a terminal node in a resource's attribute listing. Terminal nodes must return atomic values (ex: A string, an integer, etc.)
    #
    # == Parameters:
    # data::
    #   A hash that contains all of the information associated with this snapshot element. 
    #
    # == Returns:
    # The @value that is faked for this Field
    #
    def initialize name:, full_name:, data:
      @name = name
      @full_name = full_name
      @data = data
      @type = data["type"].first["code"]

      @value = set_value

      print "Faking value for #{@full_name}, "

    end

    # Key Examples
    # full_name = Patient.identifier.system
    #   full_key => Patient_identifier_system
    #   sub_key => identifier_system

    # Check if this field has a valueset associated with it, use that if it does. (TODO: This should check if the type is a Code)
    # Check if we have explitly written a yaml file for this resource_type + value (Patient.identifier.use)
    # Check if we have a yaml file just for this datatype (identifier.use)
    # Check if we have method for this type (#uri)
    # TODO: Improve our fallback. We should log this field object into some kind of TODO folder maybe.
    def set_value
      faker_full_key = "faker.name.#{@full_name.downcase}"
      faker_sub_key = "faker.name.#{@full_name.downcase.split(".").last(2).join(".")}"
      
      full_key = @full_name.gsub(".", "_").downcase
      sub_key = @full_name.split(".").last(2).join("_").downcase
      
      # Check for ValueSet
      if valueset_url = @data.dig("binding", "valueSet")
        valueset_name = underscore(valueset_url.split("/").last)
        
        if I18n.exists? "faker.name.#{valueset_name}"
          Faker::Name.send valueset_name
        else
          nil
        end

      # TODO: Check for CodeableConcept

      # Check for explicit fake options based on full name
      elsif I18n.exists? "faker.name.#{faker_full_key}"
        Faker::Name.send faker_full_key

      # Check for explicit fake options based on subset of name (last 2)
      elsif I18n.exists? "faker.name.#{faker_sub_key}"
        Faker::Name.send faker_sub_key

      # Check for application specific mapping to the full key
      elsif self.respond_to? full_key
        self.send full_key

      # Check for application specific mapping to the sub key
      elsif self.respond_to? sub_key
        self.send sub_key

      # Check for general mapping for the type
      # @type = uri
      
      elsif self.respond_to?(@type)
        self.send @type
      else
        "fail2fake"
      end
    end

    def boolean
      [true, false].sample
    end

    def uri
      Faker::Internet.url
    end

    def date
      Faker::Date.backward(days: rand(1000)).to_s
    end

    def string
      Faker::Lorem.word
    end

    def underscore(str)
      str = str.gsub(/::/, '/').
                gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
                gsub(/([a-z\d])([A-Z])/,'\1_\2').
                tr("-", "_").
                downcase
    end


    
  end
end
