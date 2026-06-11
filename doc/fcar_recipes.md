<!--
# @markup markdown
# @title FCAR recipes
-->

This page documents common patterns of client FCAR using kiba-extend's iterative cleanup functionality.

Each recipe has three components:

 1. Prep/setup job - the structure of the data required as input for the FCAR process, and any transforms that exist to streamline achieving this structure
 2. FCAR configuration - A commented version of the configuration Module to include in your project to activate this FCAR
 3. Merge job - patterns for merging the FCAR back into the rest of your project

* TOC
{:toc}

## Review and correction of programmatic value splitting {#split}

The prep and merge sections below use `:init__prep` as the job output from which we are peeling off this FCAR proccess, and thus to which we are merging its results back in.

### Prep/setup job {#splitprep}

To ease the merge process, it's recommended you break this into two jobs:

- normalize: normalizes the values to be included in the worksheet
- prep: deduplicates on normalized values and finalizes prep for the split FCAR

#### Normalization job example {#splitprepnorm}

In this example, we are pulling just the location field values out of a single migrating table and applying [the normalization described in the worksheet instructions](https://github.com/lyrasis/kiba-extend/blob/main/fcar_instructions/split_values.adoc#details-on-data-preprocessing-done-prior-to-preparing-this-worksheet) to them.

~~~ ruby
# frozen_string_literal: true

module Project
  module Jobs
    module ValueSplit
      module FcarNorm
        module_function

        def job
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :init__prep,
              destination: :value_split__fcar_norm
            },
            transformer: xforms
          )
        end

        def xforms
          Kiba.job_segment do
            transform Delete::FieldsExcept,
              fields: %i[location]
            transform FilterRows::FieldPopulated,
              action: :keep,
              field: :location
            transform Deduplicate::Table,
              field: :location

              # Adjust the normalization in a way that makes sense for the data.
              #   We want to be as aggressive as we can in normalizing, without
              #   starting to over-lump things that should be kept discrete
            transform Normalize::FieldValues,
              fields: :location,
              targets: :norm,
              xforms: [:lower],
              replacements: {
                / +/ => " ",
                /^ / => "",
                / $/ => ""
              }
            transform Replace::NormWithMostFrequentlyUsedForm,
              normfield: :norm,
              nonnormfield: :location,
              target: :normloc
            transform Delete::Fields,
              fields: :norm
          end
        end
      end
    end
  end
end
~~~

#### Prep example {#splitprepprep}

~~~ ruby
# frozen_string_literal: true

module Project
  module Jobs
    module ValueSplit
      module FcarPrep
        module_function

        def job
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :value_split__fcar_norm,
              destination: :value_split__fcar_prep
            },
            transformer: xforms
          )
        end

        def xforms
          Kiba.job_segment do
            transform Deduplicate::Table,
              field: :normloc,
              include_occs: true,
              compile_uniq_fieldvals: true
            transform Rename::Fields, fieldmap: {
              location: :unnormalizedlocations
            }

            # Set up the splitters you need here
            transform StandardFcar::SplitPrep,
              orig: :normloc,
              splitters: {
                / *; */ => :semicolon,
                / and /i => :and,
                / & / => :ampersand
              }
            transform Sort::ByFieldValue,
              field: :sort,
              mode: :string
          end
        end
      end
    end
  end
end
~~~

### FCAR configuration {#splitconfig}

~~~ ruby
# frozen_string_literal: true

module Project
    module ValueSplit
      module_function

      # Most of these settings/variables are documented in:
      #   https://lyrasis.github.io/kiba-extend/Kiba/Extend/Mixins/IterativeCleanup.html

      # Job key of the prep job to be used as input for the FCAR. Change this
      #   to whatever you have named the job in your project.
      def base_job = :value_type__split_prep

      # Don't change this without good reason. The values used to uniquely
      #   identify a corrected worksheet row
      def fingerprint_fields = %i[split_val orig]

      extend Kiba::Extend::Mixins::IterativeCleanup

      def orig_values_identifier = :prepped_row_fingerprint

      # Edit this to work with the tags in your project
      def job_tags = %i[value_type split cleanup]

      # Edit this if your worksheet data includes other headers you wish to
      #   include in the ordering
      def worksheet_field_order = %i[split_val orig split to_review
        sort]

      # Delete this if you aren't including an occurrences field or other
      #   field that should be collated. These include any fields that indicate
      #   in what field(s) a term was used; the unnormalized forms of name that
      #   may have been normalized to create the "orig" value for the FCAR
      #   process, etc.
      def collate_fields = %i[occurrences]

      # Delete this if you aren't including a numeric occurrences collated field
      #   that needs to be summed.
      def cleaned_uniq_post_xforms
        bind = binding

        Kiba.job_segment do
          mod = bind.receiver

          transform Kiba::Extend::Transforms::StandardFcar::Helpers::SumCollatedOccurrences,
            field: :occurrences,
            delim: mod.collation_delim
        end
      end

      def final_post_xforms
        Kiba.job_segment do
          # Get rid of worksheet fields required for merging back into project
          #   that could have been modified by client, and the helper
          #   `autosplit` column
          transform Delete::Fields,
            fields: %i[orig sort autosplit]
          # Reconstitute the original values of fields critical for merging from
          #   the prepped row fingerprint, and delete the fingerprint field, as
          #   it has served its purpose
          transform Fingerprint::Decode,
            fingerprint: :prepped_row_fingerprint,
            source_fields: %i[orig split_val sort],
            delete_fp: true
          transform Rename::Fields, fieldmap: {
            fp_orig: :orig,
            fp_sort: :sort
          }
          # We don't need the uncorrected `split_val` values from the
          #   fingerprint
          transform Delete::Fields,
            fields: :fp_split_val
          # Drop rows where client has deleted values from `split_val`
          transform FilterRows::FieldPopulated,
            action: :keep,
            field: :split_val
          # This and the following Deduplicate::Table step exist to
          #   prevent duplicate values being merged into the project
          #   if/when client has entered corrected split on all
          #   rows for the original data
          transform CombineValues::FromFieldsWithDelimiter,
            sources: %i[orig split_val],
            target: :combined,
            delete_sources: false,
            delim: " "
          transform Deduplicate::Table,
            field: :combined,
            delete_field: true
          # Set up so merging will keep values in their original order
          transform Sort::ByFieldValue,
            field: :sort,
            mode: :string
        end
      end

      def final_lookup_on_field = :orig
    end
end
~~~

### Merge job {#splitmerge}

This job replaces the `location` values in the original `:init__prep` output with the correctly and unambiguously delimited values from the FCAR worksheet.

~~~ ruby
# frozen_string_literal: true

module Project
  module Jobs
    module ValueSplit
      module FcarMerge
        module_function

        def job
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :init__prep,
              destination: :value_split__fcar_merge,
              lookup: [
                {jobkey: :value_split__fcar_norm, lookup_on: :location},
                {jobkey: :value_split__final, lookup_on: :orig}
              ]
            },
            transformer: xforms
          )
        end

        def xforms
          Kiba.job_segment do
            # First, merge the normalized form of each location into the table
            transform Merge::MultiRowLookup,
              lookup: loc_split__fcar_norm,
              keycolumn: :location,
              fieldmap: {normloc: :normloc}

            # Delete the old location field once normalized forms are merged in, since
            #   we are replacing with correct forms in a minute
            transform Delete::Fields, fields: :location

            # Merge in corrected values, matching on the normalized locations we just
            #   merged in, and the normalized locations in the "orig" column of the FCAR
            transform Merge::MultiRowLookup,
              lookup: loc_split__final,
              keycolumn: :normloc,
              fieldmap: {location: :split_val},
              delim: Sr.delim

            # We don't need to keep the normalized location now that we've matched on it
            transform Delete::Fields,
              fields: :normloc
          end
        end
      end
    end
  end
end

~~~
