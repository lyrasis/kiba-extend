# File Registry Entry

## Note: SourceDestRegistry

`Kiba::Extend::Registry::FileRegistryEntry` mixes in the `Kiba::Extend::Registry::SourceDestRegistry` module, which provides certain information about source and destination types necessary for validating them and preparing entries using them for use in jobs. 

If you create/use a new source or destination type in your File Registry, it will need to be added to `SourceDestRegistryConstant` or you will get errors.

(This is one of the signs I made a poor design choice around FileRegistryEntry modeling, which I now thing needs to be re-implemented using the Strategy pattern or something else. But here it is for now.)

## File Registry Data hashes in your ETL application

A file registry entry is initialized with a Hash of data about the file. This Hash will be sent from your ETL application. 

The allowable Hash keys, expected Hash value formats, and expectations about them are described below.

### `:path` 
[String] full or expandable relative path to the expected location of the file**

* default: `nil`
* required if either `:src_class` or `:dest_class` requires a path (in `PATH_REQ`)
  
### `:src_class`
[Class] the Ruby class used to read in data

* default: value of `Kiba::Extend.source` (`Kiba::Common::Sources::CSV` unless overridden by your ETL app)
* required, but default supplied if not given

### `:src_opt`
[Hash] file options used when reading in source

* default: value of `Kiba::Extend.csvopts`
* required, but default supplied if not given

### `:dest_class`
[Class] the Ruby class used to write out the data

* default: value of `Kiba::Extend.destination` (`Kiba::Extend::Destinations::CSV` unless overridden by your ETL app)
* required, but default supplied if not given

### `:dest_opt`
[Hash] file options used when writing data

* default: value of `Kiba::Extend.csvopts`
* required, but default supplied if not given

### `:dest_special_opts`
[Hash] additional options for writing out the data

* Not all destination classes support extra options. If you provide unsupported extra options, they will not be sent through to the destination class, and you will receive a warning in STDOUT. The current most common use is to define `initial_headers` (i.e. which columns should be first in file) to `Kiba::Extend::Destinations::CSV`.
* optional
  
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
* Sometimes you may need to call a job with arguments. This may be particularly useful if the same job logic can be reused many times with slightly different parameters. @todo: example. In this case creator may be a Hash with `callee` and `args` keys

NOTE: The default value for the default job method name set in `Kiba::Extend` is `:job`. You can override this in your project's base file as follows: 

    Kiba::Extend.config.default_job_method_name = :whatever

#### `Module` creator example

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

#### `Hash` creator example

Default `:job` method accepts keyword arguments, so creator is a `Hash` with a `Method` or `Module` (as described above) in as `callee`, and an arguments `Hash` passed in as `args`.

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

      Csws.registry.namespace('lkup') do
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

Note the following pattern!:

    Class or Module constant name + `.method` + method name **as symbol**

### `:lookup_on`
[Symbol] column to use as keys in lookup table created from file data

* required if file is used as a lookup source
* You can register the same file multiple times under different file keys with different `:lookup_on` values if you need to use the data for different lookup purposes

### `:desc`
[String] description of what the file is/what it is used for. Used when post-processing reports results to STDOUT

* optional

###`:tags`
[Array<Symbol>] list of arbitrary tags useful for categorizing data/jobs in your ETL

* optional
* If set, you can filter to run only jobs tagged with a given tag
* Tags I commonly use: 
  * :report_problems - reports that indicate something unexpected or that I need to do more work
  * :report_fyi - informational reports
  * :cspace - final files ready to import

