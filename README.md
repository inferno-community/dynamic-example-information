# dynamic-example-information
Project to generate example information dynamically based on a HL7 FHIR implementation guide!


# Structure

1. data: This directory contains any raw data sources that have been getting used during development. Currently this includes the us-core and R4 full specifications.
2. faker/locales: This directory contains the YAML files used to populate Faker's values. The way we are loading our values into Faker currently is functional, but a bit hacky and could be improved:
    1. Faker relies on Rails I18n (internationalization) API. The way this project is loading right now requires that we reload I18n after we require faker.
    2. Faker should be letting us add new top level namespaces, but it was not working for me. Right now *every* fake list of values we have is namespaced under Name (ex: Faker::Name.administrative_gender).
        1. Preferably we want to be able to add our own namespaces, (ex: Faker::Fhir.administrative_gender)
3. fhir_gen.rb - This is the entry point for the application. We'll want to wrap this in a rake task later, for now you can look at the bottom of the file for which Resource your loading.
```ruby
  # Running the app
  ruby fhir_gen.rb
```
4. structure_defition.rb - This class wraps up a single structure (Patient). Everything we build is attached to one of these.
5. field_set.rb - This class does all the real work of building our resource's structure. We attach one of these to the structure_defintion.example attribute, and that fieldset recursively adds more fieldsets to itself as necessary. (see comments in this file for more detail).
6. field.rb - This class represents a terminal value in our example. Each field object has all of the data associated with a single snapshot element, and the value we decided to use as our fake data. All the logic for picking some fake data is currently in here.

# TODO:
1. Use [https://github.com/onc-healthit/inferno/blob/82c5f12cc9b9a199e0595afc8efc18cae36dc349/lib/tasks/tasks.rake#L836](https://github.com/onc-healthit/inferno/blob/82c5f12cc9b9a199e0595afc8efc18cae36dc349/lib/tasks/tasks.rake#L836) to load ValueSets and potentially other types into our Faker directory.

2. Add something to handle complex DataTypes that appear as terminal values (this tricks our app a bit right now)
    1. Example: [Period](http://hl7.org/fhir/us/core/StructureDefinition-us-core-patient-definitions.html#Patient.telecom.period)

3. Add support for CodeableConcept
    1. This should be similar how we'll handle normal Codes (ValueSets).

4. Convert this application to run as a rake task.

5. Add support for control over the number of examples created (do this after it runs as a rake task).

6. Add additional methods for picking other simple values based on type (string, integer, uri), or values we want to rely on a special method for instead of Faker. Might be a good idea to move these types of methods to their own module or class.

7. Lockdown the logic around picking a fake value. This logic is a bit messy right now and it is very important for the team to understand, see Field#set_value.

8. Support for extensions.

9. Support for related attributes. Example: If telecom.system == SMS, then telecom.text should = Faker::Phone.number. This would require attributes have awareness of their siblings and their values.

# Setting up Ruby
1. (Install Rbenv)[https://github.com/rbenv/rbenv] - This is a common version manager
2. Install Ruby 2.7.2, set it as your default version, and install bundler (package manager for ruby).
    ```
    rbenv install 2.7.2
    rbenv global 2.7.2
    gem install bundler
    ```
3. Manually install required libraries (we'll add a single file to handle this for us later)
    ```
    gem install faker
    gem install pry
    ```

4. Clone this repository and navigate into the lib folder.
5. Now you should be able to run 'ruby fhir_gen.rb' and see a bunch of stuff print out.

## Tips

Obviously I can't cover all syntax differences, but I'll at least mention basic debugging/printing stuff.

1. Debugging
    1. You can add 'binding.pry' anywhere in the code to insert a debugger.
        1. If you want the process to continue after a pry just type 'exit'
        2. If you want to completely stop the process type 'send :exit'

2. Printing
    1. If you want to print something you can use either print, puts, or pp. Puts automatically includes a line ending, pp (pretty print) adds a bunch of nice formatting. Generally when debugging I use pp.
    ```ruby
      pp some_variable
    ```