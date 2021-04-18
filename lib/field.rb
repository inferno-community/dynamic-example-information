require 'date'
require 'pry'
require 'faker'
I18n.load_path += Dir[File.join(File.expand_path(File.dirname(__FILE__)), 'faker/locales/**/', '*.yml')]
I18n.reload!

module FhirGen
  class Field

    attr_accessor :name, :full_name, :data, :value, :type, :value_set, :parent, :sd

    # Represents a terminal node in a resource's attribute listing. Terminal nodes must return atomic values (ex: A string, an integer, etc.)
    #
    # == Parameters:
    # data::
    #   A hash that contains all of the information associated with this snapshot element. 
    #
    # == Returns:
    # The @value that is faked for this Field
    #
    def initialize name:, full_name:, data:, parent:
      @name = name
      @full_name = full_name
      @data = data
      @parent = parent
      set_sd
      set_type

      @value = set_value
      @value.nil? ? add_failure : add_success
    end

    # Key Examples
    # full_name = Patient.identifier.system
    # full_key => Patient_identifier_system
    # sub_key => identifier_system

    # This method is called when we decide on a fake value.
    # It follows these operations until one is successful
    # 1. Check for a YAML file to support this attribute (Faker accesses these and picks a value at random)
    # 2. Check for a method to support this attribute (we write these, see #address_city)
    # 3. Check for a method to support this attribute type (see #string, #uri)
    # 4. We have failed to fake a value, log it in log/missing_values.log
    def set_value
      # Field has a link to some special valueset, the URL might give us the key to the ValueSet
      valueset_url = @data.dig("binding", "valueSet")
      valueset_key = valueset_url ? underscore(valueset_url.split("/").last) : nil

      # Generate some keys using the fields identifier. We'll use this to look for a YAML file or a method.
      # Example: "Patient.identifier.use"
      #   fullname_key => "patient_identifier_use"
      #   shortname_key => "identifier_use"
      fullname_key = underscore(@full_name.downcase)
      shortname_key = underscore(@full_name.downcase.split(".").last(2).join("_"))

      if faker_has_key? valueset_key
        Faker::Name.send valueset_key

      elsif faker_has_key? fullname_key
        Faker::Name.send fullname_key

      elsif faker_has_key? shortname_key
        Faker::Name.send shortname_key

      # Check for application specific mapping to the full key
      elsif self.respond_to? fullname_key
        self.send fullname_key

      # Check for application specific mapping to the short key
      elsif self.respond_to? shortname_key
        self.send shortname_key

      elsif self.respond_to?(@type)
        self.send @type

      else
        nil
      end
    end

    def address_city
      Faker::Address.city
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

    def dateTime
      Faker::Date.backward(days: rand(1000)).to_s
    end

    def string
      Faker::Lorem.word
    end

    # Returns all other attributes in this field set
    def siblings
      @parent._attribute_keys.reject { |ak| ak == @name }.map { |ak| @parent.send(ak) }
    end

    # Checks if Faker has the existing key.
    # Convenience method for adding the faker.name prefix
    # I18n.exists?(nil) will return true, need the upfront check
    def faker_has_key? key
      key.nil? ? nil : I18n.exists?("faker.name.#{key}")
    end

    # Replaces any white space or delimiter characters with underscores
    # Example: "Hi::My-name_is_James" => "Hi_My_name_is_James"
    def underscore(str)
      str = str.gsub(/::/, '/').
                gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
                gsub(/([a-z\d])([A-Z])/,'\1_\2').
                tr("-", "_").
                downcase
    end

    def set_type
      type = @data["type"].first
      if type.has_key?("extension") && type["extension"].first.has_key?("valueUrl")
        @type = type["extension"].first["valueUrl"]
      else
        @type  = type["code"]
      end
    end

    def set_sd
      @sd = self
      @sd = sd.parent until sd.is_a?(StructureDefinition)
    end

    # Looks up parent objects until it finds the StructureDefintion object. Adds the failed fake attribute to the log queue.
    def add_failure
      set_sd if @sd.nil?
      @sd.add_failure field_name: @full_name
    end
    def add_success
      set_sd if @sd.nil?
      @sd.add_success field_name: @full_name
    end

  end
end
