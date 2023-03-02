# kiba-extend cookbook

A place to share patterns for handling common workflows.

## Produce cleanup worksheet for client

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
