# File Registry Entry

## Note: SourceDestRegistry

{Kiba::Extend::Registry::FileRegistryEntry} mixes in the {Kiba::Extend::Registry::SourceDestRegistry} module, which provides certain information about source and destination types necessary for validating them and preparing entries using them for use in jobs.

If you create/use a new source or destination type in your File Registry, it will need to be added to `SourceDestRegistryConstant` or you will get errors.

(This is one of the signs I made a poor design choice around FileRegistryEntry modeling, which I now thing needs to be re-implemented using the Strategy pattern or something else. But here it is for now.)

## File Registry Data hashes in your ETL application

A file registry entry is initialized with a Hash of data about the file. This Hash will be sent from your ETL application.

The allowable Hash keys, expected Hash value formats, and expectations about them are described below.

**NOTE:** (Since 3.0.0) For all keys besides `:dest_special_opts`, you may pass a Proc that returns the expected value format when called. For `:dest_special_opts`, you may pass Procs as individual values within the option Hash. This can be useful if you need to pass in a value that depends on other project config that may not be loaded/set up when registry is initially populated. A publicly available example is in `kiba-tms` which [sets destination initial headers](https://github.com/lyrasis/kiba-tms/blob/eb8f222f0dc753921e58d136cd15e5eab7472c60/lib/kiba/tms/table/prep/destination_options.rb#L32-L34) [based on the preferred name field for a given TMS client project, and whether they want to include "flipped" form as variant terms](https://github.com/lyrasis/kiba-tms/blob/eb8f222f0dc753921e58d136cd15e5eab7472c60/lib/kiba/tms/constituents.rb#L140-L148).

### `:path`
[String] full or expandable relative path to the expected location of the file**

* default: `nil`
* required if either `:src_class` or `:dest_class` requires a path (in {Kiba::Extend::Registry::SourceDestRegistry.requires_path?})

### `:src_class`
[Class] the Ruby class used to read in data. This class must be defined in the `Sources` namespace or equivalent. Example: you should never use {Kiba::Extend::Destinations::CSV} as a `src_class`value.

* required, but default supplied if not given
* default: value of {Kiba::Extend.source} (`Kiba::Common::Sources::CSV` unless overridden by your ETL app)

### `:src_opt`
[Hash] file options used when reading in source

* required, but default supplied if not given
* if `:src_class` is `Kiba::Common::Sources::CSV`:
  * default: value of {Kiba::Extend.csvopts}
* if `:src_class` is `Kiba::Common::Sources::Marc`:
  * default: `nil`
  * A hash of keyword parameters defined for [MARC::Reader](https://github.com/ruby-marc/ruby-marc/blob/main/lib/marc/reader.rb) can be entered, for example: `{external_encoding: "MARC-8", internal_encoding: "UTF-16LE"}`

### `:dest_class`
[Class] the Ruby class used to write out the data. This class must be defined in the `Destinations` namespace or equivalent. Example: you should never use `Kiba::Common::Sources::CSV` as a `:dest_class` value.

* required, but default supplied if not given
* default: value of {Kiba::Extend.destination} ({Kiba::Extend::Destinations::CSV} unless overridden by your ETL app)

### `:dest_opt`
[Hash] file options used when writing data

* required, but default supplied if not given
* if `:dest_class` is {Kiba::Extend::Destinations::CSV} or `Kiba::Common::Destinations::CSV`:
  * default: value of {Kiba::Extend.csvopts}
* if `:dest_class` is {Kiba::Extend::Destinations::JsonArray}:
  * default: `nil`

### `:dest_special_opts`
[Hash] additional options for writing out the data

* optional
* Not all destination classes support extra options. If you provide unsupported extra options, they will not be sent through to the destination class, and you will receive a warning in STDOUT. The current most common use is to define `initial_headers` (i.e. which columns should be first in file) to {Kiba::Extend::Destinations::CSV}.

Example:

```ruby
reghash = {
  path: '/path/to/file.csv',
  dest_class: Kiba::Extend::Destinations::CSV,
  dest_special_opts: { initial_headers: %i[objectnumber briefdescription] }
  }
```

### `:creator`
[Method, Module, Hash] Ruby method that generates this file

* Used to run ETL jobs to create necessary files, if said files do not exist
* Not required at all if file is supplied
* If the method that runs the job is a module instance method named `job`, creator value can just be the `Module` containing the `:job` method
* Otherwise, the creator value must be a `Method` (Pattern: `Class::Or::Module::ConstantName.method(:name_of_method)`)
* Sometimes you may need to call a job with arguments. This may be particularly useful if the same job logic can be reused many times with slightly different parameters. In this case creator may be a Hash with `callee` and `args` keys

NOTE: The default value for {Kiba::Extend.default_job_method_name} is `:job`. You can override this in your project's base file as follows (since 2.7.2):

    Kiba::Extend.config.default_job_method_name = :whatever

#### `Module` creator example  (since 2.7.2)

This is valid because the default `:job` method is present in the module:

```ruby
# in job definitions
module Project
  module Table
    module_function

    def job
	  Kiba::Extend::Jobs::Job.new(
	   ...
	  )
	end
  end
end

# in file registry
reghash = {
  path: '/project/working/objects_prep.csv',
  creator: Project::Table
}
```

#### `Method` creator example

Default `:job` method not present (or is not the method you need to call for this job).

```ruby
# in job definitions
module Project
  module Table
    module_function

    def prep
	  Kiba::Extend::Jobs::Job.new(
	   ...
	  )
	end
  end
end

# in file registry
reghash = {
  path: '/project/working/objects_prep.csv',
  creator: Project::Table.method(:prep)
}
```

#### `Hash` creator example (since 2.7.2)

Hash keys:

* `callee`: `Method` or `Module` (as described above)
* `args`: `Hash` of keyword arguments to pass to the callee

```ruby
# in your project's registry_data.rb
module Project
  module RegistryData
    module_function

    def register
      register_lookups
      register_files
      Project.registry.transform
      Project.registry.freeze
    end

    def normalized_lookup_type(type)
      type.downcase
        .gsub(' ', '_')
        .gsub('/', '_')
    end

    def register_lookups
      types = [
        'Accession Review Decision', 'Accession Type', 'Account Codes', 'ArchSite', 'Box', 'Budget Code',
        'Building', 'CityState', 'Cleaning', 'Condition Picks', 'Contact Type', 'Count Unit', 'Creator Type',
        'Cultural Affiliation', 'Department Code', 'Digitize Parameters', 'Digitizing Hardware',
        'Digitizing Software', 'Disposal Type', 'Exhibit Type', 'Format/Type', 'Genre', 'Image Resolution',
        'In Exhibit', 'Insured By', 'Loan Purpose', 'Material', 'Mount', 'NAGPRA Type', 'Owner Type',
        'Region', 'Room', 'Server Path', 'Technique', 'Treatment', 'Value'
      ]

      # This section dynamically registers a job for each of the above `types` values
      Project.registry.namespace('lkup') do
        types.each do |type|
          register Project::RegistryData.normalized_lookup_type(type).to_sym, {
            path: File.join(Project.datadir, 'working', "#{Project::RegistryData.normalized_lookup_type(type)}.csv"),
            creator: {callee: Project::Main::Lookups::Extract, args: {type: type}},
            tags: %i[lkup],
            lookup_on: :lookupvalueid
          }
        end
      end
    end

    def register files
	  ...
	end
  end
end

# in job definitions
module Project
  module Main
    module Lookups
      module Extract
        module_function

        def job(type:)
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :lkup__prep,
              destination: "lkup__#{Project::RegistryData.normalized_lookup_type(type).to_sym}".to_sym
            },
            transformer: xforms(type)
          )
        end

        def xforms(type)
          Kiba.job_segment do
            transform FilterRows::FieldEqualTo, action: :keep, field: :lookup_type, value: type
          end
        end
      end
    end
  end
end
```

### `:supplied`
[true, false] whether the file/data is supplied from outside the ETL

- default: false
- Manually set to true for:
  - original data files from client
  - mappings/reconciliations to be merged into the ETL/migration
  - any other files created external to the ETL, which only need to be read from and never generated by the ETL process
  - entries where `:src_class` is {Kiba::Extend::Sources::Marc}

Both of the following are valid:

```ruby
reghash = {
  path: '/project/working/objects_prep.csv',
  creator: Project::ClientData::ObjectTable.method(:prep)
}

reghash = {
  path: '/project/clientData/objects.csv',
  supplied: true
}
```

### `:lookup_on`
[Symbol] column to use as keys in lookup table created from file data

* required if file is used as a lookup source
* You can register the same file multiple times under different file keys with different `:lookup_on` values if you need to use the data for different lookup purposes

Currently lookups can only be done on supplied files with CSV source, or created-by-job entries with CSV output.

### `:desc`
[String] description of what the file is/what it is used for. Used when post-processing reports results to STDOUT

* optional

### `:tags`
[Array (of Symbols)] list of arbitrary tags useful for categorizing data/jobs in your ETL

* optional
* If set, you can filter to run only jobs tagged with a given tag (or tags)1
* Tags I commonly use:
  * :report_problems - reports that indicate something unexpected or that I need to do more work
  * :report_fyi - informational reports
  * :postmigcleanup - for reports I will need to generate for client after production migration is complete
  * :cspace or :ingest- final files ready to import
