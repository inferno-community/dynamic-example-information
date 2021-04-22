# dynamic-example-information
Project to generate example information dynamically based on a HL7 FHIR implementation guide!

# Running the App
We currently have 3 rake tasks. Use these to run code. You might need to run 'bundle install' first.
```
# Task 1 - Single resource usage
rake fhir_gen:test[patient]

# Task 2 - Multi-Resource usage (untested)
rake fhir_gen:us_core_set[patient,encounter]

# Task 3 - Full Spec usage [num_examples,example_mode]
rake fhir_gen:run_all[1,random]
rake fhir_gen:run_all[1,max]
rake fhir_gen:run_all[1,min]
```

# Directories

1. lib: App code
2. lib/data: Contains any raw data sources that have been getting used during development. Includes: us-core and R4 full spec.
3. lib/faker/locales: Contains the YAML files used to populate Faker's values.
4. examples: Output for JSON representation of the created example. Current out is in the "pretty format".
5. logs: Logs any values that the application failed to fake.

# Class Files
1. fhir_gen.rb: Entry point for application
2. tasks.rake: CLI definitions for running the application.
3. structure_defition.rb - Wraps up a single resource example. StructureDefinition's always have 1 Fieldset.
4. field_set.rb - Does all the real work of building our resource's structure. Fieldsets have 0..* other fieldsets & fields.
5. field.rb - This class represents a terminal atomic value in our example. Has all of the data associated with a single snapshot element, and the value we decided to use as our fake data. All the logic for picking some fake data is currently in here.

# TODO:
1. Convert objects back into valid FHIR JSON. FieldSet#to_h method currently gets us to JSON.
    1. This can either be a post-process method in StructureDefintion (see StructureDefintion#write_example) OR our FieldSet/Fields need to know how to present themselves.

2. Support for extensions.

3. Node name's with ':' in them cannot be faked

4. Node name's that share their name with a default Ruby Object method cannot be faked

# Ruby Tips

1. Add a binding.pry anywhere in the code to stop execution and take a look.
    1. 'exit' will continue execution
    2. 'send :exit' will completely stop execution

2. Run 'bundle install' after a pull if you are having dependency issues. I added a Gemfile, which is the equivalent of a requirements.txt.