# dynamic-example-information
Project to generate example information dynamically based on a HL7 FHIR implementation guide!

# Running the App
There is currently a single rake task maintained for running the application.
```
# Running the application across US Core IG, creating 2 examples per resource, using the maximum cardinality allowed (with a ceiling of 3). 'lib/data/uscore' Must contain US Core package.
rake fhir_gen:run[uscore,2,max]

```

# Directories

1. lib: App code
2. lib/data: Contains any raw data sources that have been getting used during development. IG packages should be placed here, and their name fed into the rake task.
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
1. Support for extensions.

2. Node name's with ':' in them cannot be faked

3. Node name's that share their name with a default Ruby Object method cannot be faked

4. Missing ValueSets (the majority of failed values are codes)

# Ruby Tips

1. Add a binding.pry anywhere in the code to stop execution and take a look.
    1. 'exit' will continue execution
    2. 'send :exit' will completely stop execution

2. Run 'bundle install' after a pull if you are having dependency issues. I added a Gemfile, which is the equivalent of a requirements.txt.