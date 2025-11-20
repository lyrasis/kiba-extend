<!--
# @markup markdown
# @title File Registry Entry Reference
-->

# File Registry Entry Reference

## What are file registry entries?

A file registry entry is initialized with a Hash of data about a file. Depending on the details, this allows a given entry to be:

- the destination of one job;
- a source for another job; and
- a lookup for yet another job

Creating file registry entries and referring to them when setting up your project's jobs has two major benefits:

- a given entry may be reused in different ways, in many jobs, without having to specify details about how to find and read/write the associated file each time it is used
- Kiba::Extend can generate all non-supplied dependencies for any job automatically

## Types of file registry entries

- **supplied entries**: These entries represent files that are not created by jobs in your project application. Indicate that an entry is supplied by including `supplied: true` in the registry entry hash. Supplied entries can be used as sources and, depending on the type of file, as lookups in jobs. They cannot be used as destinations for jobs, since, by definition, files created by jobs are not supplied.
- **job entries**: These entries represent files that are output as the destination by a job in your project application. A job entry hash must have a `creator` key, indicating the job that creates the file. The job pointed at by an entry's `creator` must have that entry as its destination in the file config of the job.

## File registry entries in your ETL application

File registry entries are defined as Ruby `Hash`es in your ETL application.

In the most basic Kiba::Extend project, these hashes will be manually entered in the `YourProject::RegistryData.register_files` method.

You can also write code to dynamically generate registry entry `Hash`es that follow a pattern. The [kiba-extend-project repository](https://github.com/lyrasis/kiba-extend-project/blob/main/lib/ke_project/registry_data.rb) provides some examples. See also {file:docs/common_patterns_tips_tricks.md#automating-repetitive-file-registry}.

Kiba::Extend converts these `Hash`es to {Kiba::Extend::Registry::FileRegistryEntry} classes when you call {Kiba::Extend::Registry::FileRegistry.finalize} or {Kiba::Extend::Registry::FileRegistry.transform} on your project's registry.

## File registry `Hash` format

The allowable Hash keys, expected Hash value formats, and expectations about them are described below.

**NOTE:** (Since 3.0.0) For all keys besides `:dest_special_opts`, you may pass a Proc that returns the expected value format when called. For `:dest_special_opts`, you may pass Procs as individual values within the option Hash. This can be useful if you need to pass in a value that depends on other project config that may not be loaded/set up when registry is initially populated. A publicly available example is in `kiba-tms` which [sets destination initial headers](https://github.com/lyrasis/kiba-tms/blob/eb8f222f0dc753921e58d136cd15e5eab7472c60/lib/kiba/tms/table/prep/destination_options.rb#L32-L34) [based on the preferred name field for a given TMS client project, and whether they want to include "flipped" form as variant terms](https://github.com/lyrasis/kiba-tms/blob/eb8f222f0dc753921e58d136cd15e5eab7472c60/lib/kiba/tms/constituents.rb#L140-L148).

### `:path`
[String] full path or expandable relative path to the expected location of the file associated with the registry entry. If it is a supplied entry, the file must be present at this location. If it is a job entry, this is the location where the output of the job is written.

* default: `nil`
* A path String value is required if either `:src_class` or `:dest_class` requires a path

### `:src_class`
[Class] the Ruby class used to read in data. This class must be defined in the `Sources` namespace or equivalent. That is, {Kiba::Extend::Destinations::CSV} will not work as a `src_class` value.

* required, but default supplied if not given
* default: value of {Kiba::Extend.source} (This will be `Kiba::Extend::Sources::CSV` unless overridden by your ETL app)

### `:src_opt`
[Hash] file options used when reading in source

* required, but default supplied if not given
* if `:src_class` is `Kiba::Extend::Sources::CSV`:
  * default: value of {Kiba::Extend.csvopts}
* if `:src_class` is `Kiba::Extend::Sources::Marc`:
  * default: `nil`
  * A hash of keyword parameters defined for [MARC::Reader](https://github.com/ruby-marc/ruby-marc/blob/main/lib/marc/reader.rb) can be entered, for example: `{external_encoding: "MARC-8", internal_encoding: "UTF-16LE"}`

### `:dest_class`
[Class] the Ruby class used to write out the data. This class must be defined in the `Destinations` namespace or equivalent. That is, `Kiba::Extend::Sources::CSV` will not work as a `:dest_class` value.

* required, but default supplied if not given
* default: value of {Kiba::Extend.destination} (This will be {Kiba::Extend::Destinations::CSV} unless overridden by your ETL app)

### `:dest_opt`
[Hash] file options used when writing data

* required, but default supplied if not given
* if `:dest_class` is {Kiba::Extend::Destinations::CSV}
  * default: value of {Kiba::Extend.csvopts}
* if `:dest_class` is {Kiba::Extend::Destinations::JsonArray}:
  * default: `nil`

### `:dest_special_opts`
[Hash] additional options for writing out the data

* optional
* Only the following destination classes support extra options. If you provide unsupported extra options, they will not be sent through to the destination class, and you will receive a warning in STDOUT.
  * {Kiba::Extend::Destinations::CSV} (`initial_headers`)
  * {Kiba::Extend::Destinations::Marc} (`allow_oversized`) - Sets the `MARC::Writer` created by the destination to allow oversized records. See [`MARC::Writer` code](https://github.com/ruby-marc/ruby-marc/blob/main/lib/marc/writer.rb) for explanation.

Examples:

~~~ ruby
reghash = {
  path: '/path/to/file.csv',
  dest_class: Kiba::Extend::Destinations::CSV,
  dest_special_opts: { initial_headers: %i[objectnumber briefdescription] }
  }
~~~

~~~ ruby
reghash = {
  path: '/path/to/long_marc_records.mrc',
  dest_class: Kiba::Extend::Destinations::Marc,
  dest_special_opts: { allow_oversized: true }
  }
~~~

### `:creator`
[Method, Module, Hash] to run the job and create the expected output

* Used to run ETL jobs to create necessary files, if said files do not exist
* Not required if file is supplied
* When to give a `Method`, `Module`, or `Hash` as `:creator` is described below.

#### `Module` creator example  (since 2.7.2)

The default value for {Kiba::Extend.default_job_method_name} is `:job`. You can override this in your project's base file as follows (since 2.7.2):

    Kiba::Extend.config.default_job_method_name = :whatever

* If the method that runs the job is a module instance method with the default job method name, the `:creator` can be the `Module` containing that method

This is valid because the default `:job` method is present in the module:

~~~ ruby
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
~~~

#### `Method` creator example

If the method that runs the job is not the default job method name, you must set a `Method` as `:creator`:

~~~ ruby
# in job definitions
module Project
  module Table
    module_function

    def prepjob
	  Kiba::Extend::Jobs::Job.new(
	   ...
	  )
	end
  end
end

# in file registry
reghash = {
  path: '/project/working/objects_prep.csv',
  creator: Project::Table.method(:prepjob)
}
~~~

#### `Hash` creator example (since 2.7.2)

You may wish to call a job with arguments if the same job logic can be reused many times with slightly different parameters. In this case, `:creator` may be a Hash with `callee` and `args` keys

Hash keys:

* `callee`: `Method` or `Module` (as described above)
* `args`: `Hash` of keyword arguments to pass to the callee

In your project's `registry_data.rb`:

~~~ ruby
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
        'Accession Review Decision', 'Accession Type', 'Account Codes', 'ArchSite'
      ]

      # This section dynamically registers a job for each of the above `types` values within the
	  #   `lkup` namespace
      Project.registry.namespace('lkup') do
        types.each do |type|
          register Project::RegistryData.normalized_lookup_type(type).to_sym, {
            path: File.join(
			  Project.datadir,
			  'working',
			  "#{Project::RegistryData.normalized_lookup_type(type)}.csv"
		    ),
            creator: {
			  callee: Project::Main::Lookups::Extract,
			  args: {type: type}
		    },
            tags: %i[lkup],
            lookup_on: :lookupvalueid
          }
        end
      end
    end

    def register files
	  # ...snip...
	end
  end
end
~~~


In your job definition Module:

~~~ ruby
module Project
  module Main
    module Lookups
      module Extract
        module_function

        def job(type:)
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :lkup__prep,
              destination: :"lkup__#{Project::RegistryData.normalized_lookup_type(type)}"
            },
            transformer: xforms(type)
          )
        end

        def xforms(type)
          Kiba.job_segment do
            transform FilterRows::FieldEqualTo,
			action: :keep,
			field: :lookup_type,
			value: type
          end
        end
      end
    end
  end
end
~~~

### `:supplied`
[true, false] whether the file/data is supplied from outside the kiba-extend project

- default: false
- Manually set to true for:
  - original data files from client
  - mappings/reconciliations to be merged into the ETL/migration
  - any other files created external to the ETL, which only need to be read from and never generated by the ETL process

Both of the following are valid:

~~~ ruby
reghash = {
  path: '/project/working/objects_prep.csv',
  creator: Project::ClientData::ObjectTable.method(:prep)
}

reghash = {
  path: '/project/clientData/objects.csv',
  supplied: true
}
~~~

### `:lookup_on`
[Symbol] column to use as keys in lookup table created from file data

* required if file is used as a lookup source in any job AND that job defines this lookup file for use in the job only by its file key

If the output of a given entry is expected to be used as a lookup on only one field, set a `:lookup_on` value in the registry.

If you need to lookup in the output data on different columns, either within one job or in different jobs, this can be achieved by providing more information in the job definition's `files[:lookup]` value, starting with v5.1.0. See {Kiba::Extend::Jobs} for details. (Or you can register the same file multiple times under different file keys with different `:lookup_on` values, but yuck to that)

Currently only the following types of registry entries can be used as lookups:

* Supplied registry entries where the `:src_class` returns each row/record as a Ruby `Hash`
* Job registry entries where the `as_source_class` class attribute of the `:dest_class` returns each row/record as a Ruby `Hash`

Other types of registry entries should not define a `:lookup_on` value.

### `:desc`
[String] description of what the file is/what it is used for. Used when post-processing reports results to STDOUT

* optional

### `:tags`
[Array (of Symbols)] list of arbitrary tags useful for categorizing data/jobs in your ETL

* optional
* If set, you can filter to run only jobs tagged with a given tag (or tags)
* Tags I commonly use:
  * :report_problems - reports that indicate something unexpected or that I need to do more work
  * :report_fyi - informational reports
  * :postmigcleanup - for reports I will need to generate for client after production migration is complete
  * :cspace or :ingest- final files ready to import

You can do `thor reg:tags` to see a list of all tags already defined in your registry.
