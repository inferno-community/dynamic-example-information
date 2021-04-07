require 'pry'

module FhirGen
  class FieldSet

    attr_accessor :elements, :_attribute_keys

    # FieldSet objects do the heavy lifting of constructing a resources structure. An attribute is for every element/node in the snapshot.
    # See add_attributes_from_snapshot for detail.
    #
    # == Parameters:
    # name::
    #   String representation of this node in the attribute tree. Examples: "Patient", "identifier", "use"
    #
    # full_name::
    #   String representation of the entire path to this node. Example: "Patient.identifier.use"
    #
    # snapshot::
    #   An Array of hashes, where each hash is a node in the attribute tree. These are the primary units we are processing.
    #
    # example_mode::
    #   Symbol representing a strategy we will use to pick the number of elements to make. We do not yet support this.
    #     Example - Given :random, and cardinality 0..3, make rand(3) examples. :max or :min would be other valid options.
    # 
    # n_examples_ceiling::
    #   Integer representing the total number of examples we will generate when given the option. If cardinality requires more 
    #   than n_examples_ceilings, ignore the ceiling
    #     Example - Given 3, and cardinality 1..5, treat cardinality as 1..3
    #
    # == Returns:
    # N/A
    #
    def initialize name:, full_name:, snapshot:, example_mode: :random, n_examples_ceiling: 3
      @_snapshot = snapshot
      @_name = name
      @_full_name = full_name
      @_example_mode = example_mode
      @_n_examples_ceiling = n_examples_ceiling

      @_attribute_keys = []
      add_attributes_from_snapshot if @_snapshot
    end

    # Processes the elements in the snapshot until their are none left. First check cardinality, then check type. This method recursively builds more FieldSet objects ontop of this one when it reaches any attribute that is not a terminal attribute/node.
    # 
    # Cardinality: For every attribute, check cardinality to decide if this value will be atomic or a list. Note that this has no bearing on the # complexity of the value (whether its a single value like gender, or a complex value such as Identifier or HumanName)
    # 
    # Type: Check if this attribute consists of terminal node(s) (ex: "Patient.gender" => "Male" or some complex type (ex: "HumanName"). This is used to determine if we will be adding Field(s) or FieldSet(s) objects for the attribute.
    #
    # Using cardinality and type, we know how to fill this attribute. If the node is atomic/terminal, we will add some number of Field objects. If the node is not terminal, we will cut all of its decendant nodes from the snapshot, and use them to add some number of FieldSets at this attribute.
    #
    # Full Example:: 
    #   We have reached the snapshot element "Patient.name". It has cardinality 1..*, so we will set self.name = [] to support 1 to Many.
    #   This node has decendant nodes, such as Patient.name.use and Patient.name.text, which means this node is not terminal.
    #   Since it is not terminal we'll be creating FieldSet object(s) here. In this case some random number of them between 1 and 3.
    #   The new FieldSet objects will process those descendant nodes and keep pushing down to terminal values (Fields) or new FieldSets.
    #   self.name is now [FieldSet1, FieldSet2...], where each FieldSet is an object with the attributes for a HumanName's top level nodes.
    #
    # == Returns:
    # N/A
    #
    def add_attributes_from_snapshot
      while node = @_snapshot.shift do
        full_name = node["id"]
        node_name = full_name.split(".").last

        if node["type"].nil?
          puts "Node with id #{full_name} skipped for no type"
          next
        end

        node_type = node["type"].first["code"]
        cardinality = get_cardinality(min: node["min"], max: node["max"])
        n_examples = get_n_examples(cardinality: cardinality)
        
        # Not ready for extensions yet
        next if node_type == "Extension"

        # Cardinality 0..1.size => 2
        # Need to use size to properly compare cardinality.size => Infinite
        attr_val = (cardinality.size) > 2 ? [] : nil

        # The attribute has multiple type options. We should randomly pick one, for now just using #1
        if node_name.include? "[x]"
          node_name = node_name.gsub("[x]","") + node_type[0].upcase + node_type[1..-1]
        end
        add_attribute(attr_name: node_name, attr_val: attr_val)

        child_nodes = []
        @_snapshot.delete_if { |ss_element| child_nodes << ss_element if ss_element["id"].start_with?("#{full_name}.") }

        if child_nodes.any?

          n_examples.times do
            fieldset = FieldSet.new name: node_name, full_name: full_name, snapshot: child_nodes.dup
            fill_attribute node_name: node_name, obj: fieldset
          end
        else
          field = Field.new name: node_name, full_name: full_name, data: node
          fill_attribute node_name: node_name, obj: field
        end

      end
    end
    
    # Convert this FieldSet into a hash (dictionary). If this FieldSet has FieldSets at other attributes, just keep calling to_h on those.
    def to_h
      h = {}
      self._attribute_keys.each do |attr_key|
        attr_val = self.send attr_key
        if attr_val.is_a? Array
          h[attr_key] = []

          attr_val.each do |_attr_val|
            h[attr_key] << (_attr_val.is_a?(FieldSet) ? _attr_val.to_h : _attr_val.value )
          end
        else
          h[attr_key] = (attr_val.is_a?(FieldSet) ? attr_val.to_h : attr_val.value )
        end
      end
      h
    end

    private
    
    # Dynamically adds an attribute to this instance of the StructureDefinition.
    # Example:
    # sd = StructureDefinition.new
    # sd.add_attribute(attr_name: "first_name", attr_val: "John")
    # sd.first_name => "John"
    def add_attribute attr_name:, attr_val: nil
      return if self.respond_to? attr_name

      @_attribute_keys << attr_name
      singleton_class.class_eval { attr_accessor attr_name.to_s }
      send("#{attr_name}=", attr_val)
    end

    # If the attribute at this node is a collection, insert it. Otherwise just set it
    # Equivalent of self.identifiers << obj and self.identifiers= obj
    # Obj is either a fieldset or field
    def fill_attribute node_name:, obj:
      if self.send(node_name).is_a? Array
        self.send(node_name).send("<<", obj)
      else
        self.send("#{node_name}=", obj)
      end
    end

    # Return a Range object representing the cardinality of this node.
    # 0..* => (0..nil)
    # 0..2 => (0..2)
    def get_cardinality min:, max:
      card_min = is_number?(min) ? min.to_i : nil
      card_max = is_number?(max) ? max.to_i : nil
      Range.new(card_min, card_max)
    end

    # Placeholder for logic picking random numbers of examples given ranges of cardinality. Currently just picks the ceiling for infinite or random otherwise.
    def get_n_examples cardinality:
      cardinality.size.infinite? ? @_n_examples_ceiling : cardinality.to_a.sample
    end

    # Checks if i is a valid number regardless of type. 
    # us-core Patient snapshot has cardinality of min: 1 and max: "1" - need to accept the string rep.
    def is_number? i
      true if Float(i) rescue false
    end

  end
end