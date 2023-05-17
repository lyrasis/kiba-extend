# kiba-extend cookbook

A place to share patterns for handling common workflows.

## Generate unique subject headings used in multiple fields, across multiple data sources

Client data includes multiple tables. One or more fields from each table will end up mapping to `subject`. We need a list of all unique values mapping to `subject` for client to review, and/or to use as a base for producing a cleanup worksheet. Sample data:

- coll1.csv - `mainsub`, `addtlsub` fields contain subject values
- coll2.csv - `subject` field contains subject values

Assume we have already registered supplied entries for these data sources:

- :orig__coll1
- :orig__coll2

I'm going to set this up so that it can easily scale.

### Create extract job to get unique subject values from each field in a consistent way

First, create a job that accepts parameters. This will be used to isolate your subject field columns so they can be used as data sources. This job will drop rows with no subject values, and deduplicate each individual column, so our eventual combined list is smaller. It will also rename each source field to :subject.

```
# clientproject/lib/client/jobs/subjects/extract_field_vals.rb

module Client
  module Jobs
    module Subjects
      module ExtractFieldVals
        module_function

        # @param source [Symbol] registry entry key of source, without namespace
        # @param dest [Symbol] registry entry key of destination, without namespace
        # @param field [Symbol] field containing subject values
        def job(source:, dest:, field:)
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: "orig__#{source}".to_sym,
              destination: "subjects__#{dest}".to_sym
            },
            transformer: xforms(field)
          )
        end

        def xforms(field)
          Kiba.job_segment do
            transform Delete::FieldsExcept,
              fields: field
            transform FilterRows::FieldPopulated,
              action: :keep,
              field: field
            transform Rename::Field,
              from: field,
              to: :subject
            transform Deduplicate::Table,
              field: field,
              delete_field: false
          end
        end
      end
    end
  end
end
```

**TIP: Have multi-values in subject field?**

Put this before you rename the field:

```
transform Explode::RowsFromMultivalField,
  field: field,
  delim: '|'
```

**TIP: Have multi-values in subject field AND you want the unique _subject subdivisions_?**

Note: This creates a 2-column output for each subject field. You get the whole subject field value, so there's at least one example of the subdivision used in context.

Put this before you rename the field:

```
transform Explode::RowsFromMultivalField,
  field: field,
  delim: '|'
```

Put this after you rename the field:

```
transform Copy::Field,
  from: :subject,
  to: :subdivision
transform Explode::RowsFromMultivalField,
  field: :subdivision,
  delim: '--'
transform Clean::StripFields, fields: :subdivision
```

Then, change the field you deduplicate on to :subdivision.

### Set up registry entries to dynamically extract and compile the field data based on config

Set up your registry stuff to call this job dynamically for whatever sources you give it:

```
Client.registry.namespace("subjects") do
  # Here is where you configure your subject value sources. If you have
  #   followed naming pattern/convention, then you don't have to touch
  #   this again
  src_cfg = [
    ["coll1", :mainsub],
    ["coll1", :addtlsub],
    ["coll2", :subject]
  ]
  # We'll use this as an argument passed to our compilation job. It just
  #   creates the full registry entry keys with namespaces that will be
  #   sources for that job
  subject_srcs = src_cfg.map do |cfg|
    "subjects__#{cfg[0]}_#{cfg[1]}".to_sym
  end

  # Dynamically create individual source field extract jobs
  src_cfg.each do |cfg|
    src = cfg[0]
    field = cfg[1]
    dest = "#{src}_#{field}".to_sym
    register dest, {
      path: File.join(Client.datadir, "working",
                      "subjects_from_#{dest}.csv"),
      creator: {
        callee: Client::Jobs::Subjects::ExtractFieldVals,
        args: {source: src, dest: dest, field: field}
      }
    }
  end
  # This is also called with args, so the sources can be based on
  #   the `src_cfg` you entered above
  register :compile, {
    path: File.join(Client.datadir, "working", "subjects_compiled.csv"),
    creator: {
      callee: Client::Jobs::Subjects::Compile,
      args: {sources: subject_srcs}
    }
  }
end
```

### Write the compile job, taking its sources as an argument

And the compile job you'll call to generate the list of all unique values. This is going to read in all the rows from all the single-column jobs and deduplicate the values:

```
module Client
  module Jobs
    module Subjects
      module Compile
        module_function

        # @param sources [Array<Symbol>]
        def job(sources:)
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: sources,
              destination: :subjects__compile
            },
            transformer: xforms
          )
        end

        def xforms
          Kiba.job_segment do
            transform Deduplicate::Table,
              field: :subject,
              delete_field: false
          end
        end
      end
    end
  end
end
```

## Run the compilation job

```
thor run job subjects__compile
```

Everything else runs automagically in the background.

Well, if any of your subject field sources ends up not writing a CSV file because there are no values in the field, this will fail. The easiest thing to do is remove that source from your `src_cfg` array.

If your project is more dynamic, you can add a method like this somewhere:

```
module Client
  # @param jobkey [Symbol]
  def job_output?(jobkey)
    reg = Client.registry.resolve(jobkey)
    return false unless reg
    return true if File.exist?(reg.path)

    res = Kiba::Extend::Command::Run.job(jobkey)
    return false unless res

    !(res.outrows == 0)
  end
end
```

And register your compilation job like:

```
  register :compile, {
    path: File.join(Client.datadir, "working", "subjects_compiled.csv"),
    creator: {
      callee: Client::Jobs::Subjects::Compile,
      args: {sources: subject_srcs.select{ |key| Client.job_output?(key) }}
    }
  }
```

## Produce `description` field cleanup worksheet for client

Client has >10,000 source records. Their `description` field is free-text, but they have mostly entered data by cutting and pasting from the data entry guide for their previous system. However, some irregularities have crept in that they would like to clean up. Some of these irregularities may have been copied to many records by cloning records in the source system.

We want to provide an efficient way for the client to review and provide corrections for any irregular values.

We assume there will be other fields they may also want to clean up in a similar way, so we want to set up a pattern for this.

Create a namespace in the registry for cleanup worksheets. Register the output of the job that will create the `description` cleanup worksheet:

```
# in clientproject/lib/client/registry_data.rb

Client.registry.namespace("cleanup_wrkshts") do
  register :description, {
    path: File.join(Client.datadir, "to_client", "description_cleanup.csv"),
    creator: Client::Jobs::CleanupWrkshts::Description
  }
end
```

Here is the job to create the worksheet. The source data is in CSV format, with >10,000 rows and >30 columns:

```
# clientproject/lib/client/jobs/cleanup_wrkshts/description.rb

module Client
  module Jobs
    module CleanupWrkshts
      module Description
        module_function

        def job
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :base__data,
              destination: :cleanup_wrkshts__description
            },
            transformer: xforms
          )
        end

        def xforms
          Kiba.job_segment do
		    # We only care about the description values in the cleanup worksheet
            transform Delete::FieldsExcept,
              fields: :description
            transform FilterRows::FieldPopulated,
              action: :keep,
              field: :description
            transform Deduplicate::Table,
              field: :description,
              delete_field: false
		    # Create the field they'll enter any corrections into
            transform Append::NilFields,
              fields: %i[corrected]
          end
        end
      end
    end
  end
end
```

This produces a CSV with ~500 rows, with all unique `description` field values: a much more manageable cleanup project.

The cleanup instructions specify that the client should only edit the `corrected` field.

If the existing value needs correction, they should enter the correct value in `corrected`. If the existing value is ok, they should leave `corrected` blank.

**Note:** If there is a need for the client to sort/review the existing and corrected values together as part of the cleanup, I will normally generate an Excel workbook from the worksheet CSV and add a review/sort column with a formula like:

`=if(isblank(b2),a2,b2)`

(This assumes original value in column A, corrected in column B)

## Merging client corrections back into migration

This assumes you have set things up as described in the Produce cleanup worksheet for client section above.

Client returns completed worksheet. If it was provided to them as Excel workbook, convert it back to CSV.

Make a registry entry for this supplied file:

```
# in clientproject/lib/client/registry_data.rb

Client.registry.namespace("cleanup_done") do
  register :description, {
    path: File.join(Client.datadir, "from_client", "description_cleanup.csv"),
    supplied: true
  }
end
```

We will also set up a job to keep only the corrections, so our lookup and merge of corrections into the migration can be faster (this gets us neglible gains in most migration projects, but is illustrative...):

```
# clientproject/lib/client/jobs/cleanup_prep/description.rb

module Client
  module Jobs
    module CleanupPrep
      module Description
        module_function

        def job
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :cleanup_done__description,
              destination: :cleanup_done__description_prep
            },
            transformer: xforms
          )
        end

        def xforms
          Kiba.job_segment do
            transform FilterRows::FieldPopulated,
              action: :keep,
              field: :corrected
          end
        end
      end
    end
  end
end
```

Make a registry entry for that job's output. We are going to want to look up the corrected `description` value by the original `description` value, so we record that, if used as a lookup source, the output of the `:description_prep` job entry will be indexed/looked up on the `description` field. Our `cleanup_done` registry namespace now looks like:

```
# in clientproject/lib/client/registry_data.rb

Client.registry.namespace("cleanup_done") do
  register :description, {
    path: File.join(Client.datadir, "from_client", "description_cleanup.csv"),
    supplied: true
  }
    register :description_prep, {
    path: File.join(Client.datadir, "working", "description_cleanup.csv"),
    creator: Client::Jobs::CleanupPrep::Description,
	lookup_on: :description
  }
end
```

Finally, create and register a job that merges the corrected data:

```
Client.registry.namespace("cleanup_merge") do
  register :field_cleanup, {
    path: File.join(Client.datadir, "working", "cleaned_field_data_merged.csv"),
    creator: Client::Jobs::CleanupMerge::FieldCleanup
  }
end

# in clientproject/lib/client/jobs/cleanup_merge/field_cleanup.rb

module Client
  module Jobs
    module CleanupMerge
      module FieldCleanup
        module_function

        def job
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :base__data,
              destination: :cleanup_merge__field_cleanup,
              lookup: %i[
                         cleanup_done__description_prep
                         ]
            },
            transformer: xforms
          )
        end

        def xforms
          Kiba.job_segment do
            %i[description].each do |field|
              corrfield = "#{field}_corr".to_sym

              transform Merge::MultiRowLookup,
                lookup: send("cleanup_done__cdm1_#{field}".to_sym),
                keycolumn: field,
                fieldmap: {corrfield=>:corrected}

              transform do |row|
                corrval = row[corrfield]
                next row if corrval.blank?

                row[field] = corrval
                row
              end
              transform Delete::Fields, fields: corrfield
            end
          end
        end
      end
    end
  end
end
```

This looks a little weird, but if we later add a date cleanup that follows the same pattern, we can merge that in by making two minor changes:

```
lookup: %i[
           cleanup_done__description_prep
           ]
```

becomes:

```
lookup: %i[
           cleanup_done__description_prep
		   cleanup_done__date_prep
           ]
```

And

```
%i[description].each do |field|
```

becomes:

```
%i[description date].each do |field|
```

If you have a number of cleanup jobs like this, which follow the same pattern, you could also [automate repetitive file registry](https://lyrasis.github.io/kiba-extend/file.common_patterns_tips_tricks.html#automating-repetitive-file-registry) and create the prep job (and maybe worksheet creation job) as [jobs that take parameters](https://lyrasis.github.io/kiba-extend/file.common_patterns_tips_tricks.html#calling-a-job-with-parameters).
