<!--
# @markup markdown
# @title FCAR recipes
-->

This page documents common patterns of client FCAR using kiba-extend's iterative cleanup functionality. At the bottom, there is also a section that collects patterns for writing automated tests of FCAR processes that you develop.

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

## Patterns and considerations for testing FCAR processes

### Test data

These are recommended practices based on the policies and workflows of the Lyrasis Data Migrations Team, but may be useful for others to consider.

We do not recommend the project's `datadir` be inside the project's code repository.
We avoid pushing client data up into GitHub, even in private repositories.

Typically test fixture files are stored in a project's `./spec/support/fixtures` directory, but we won't be able to do that with real client data.

For collaboration, code exploration/learning, and succession planning purposes, we recommend  uploading any FCAR worksheets provided to the client, and any completed worksheets they return to the Team SharePoint Projects folder for the project. Mirror the `to_client` and `supplied` subdirectories.

It is onerous to produce realistic fake test data for individual migration projects. It's typically safer to test on real client data. Also, typically, an individual migration project codebase is quick-moving and doesn't require pull requests or GitHub Actions, since only one Migration Specialist is typically developing the project. In this case, we don't care about tests failing via GitHub Actions because the test data is not in the repository.

We do want anyone working on the project to be able to run the tests successfully on their computer, whether they are picking up in the middle of project or not. For this reason we recommend any necessary fixture files be stored in `fixtures` subdirectories of `to_client` and `supplied`. If other test files need to be created that do not belong in `to_client` or `supplied`, store them in a `datadir/fixtures` directory that you also mirror to SharePoint as you add files.

### Patterns

#### Lightweight spot checking of values in FCAR process jobs with different state setup

See: [Common patterns, tips, and tricks > Manipulating the registry on the fly](https://lyrasis.github.io/kiba-extend/file.common_patterns_tips_tricks.html#manipulate-registry)

#### Full file/FCAR workflow testing in a large parent project

This is a partial test file from the `kiba-tms` repository (private).

Since this is a parent project with no specific client data, it is appropriate to create and store test data in the repository.

There are some things in here that I'm not providing the code for, since it probably isn't relevant outside this project, but I'll explain what each thing does in comments.

I do provide the full `setup_project` method below because it is complicated, but mostly self-contained. This is an older project, last worked on before I added a `Kiba::Extend.reset_registry` method, so I would do a lot of this differently now. But it is a good representation of the kind of complex setup that might be involved.

##### Test file

~~~~ruby
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Jobs::Places do
  context "when no cleanup done", :initial do
    it "transforms as expected" do
      # This project has over 150 separate config modules so this is an convenience
      #   method in its `./spec/helpers.rb` file that cycles through them all
      #   programmatically and calls `#{module}.reset_config` on each.
      reset_configs

      # Clears the contents of relevant directories containing derived files, to
      #   avoid polluting the state setup. As seen in `setup_project`, we are setting
      #   this up to run with `Kiba::Extend.config.pre_job_task_mode` inactivated
      #   because every time `result_path` is called, that job is being run and its
      #   output path is returned to use in the test.
      clear_working

      # We copy the fixture base file for this stage out of where we store it
      #   in the code repo, to the expected path for it, if it were run in real life
      copy_from_test("places_norm_unique_N0.csv")

      # With these config settings, `Kiba::Tms::Jobs::Places.cleanup_done?` is falsey.
      Tms::Places.config.returned = []
      Tms::Places.config.worksheets = []

      # See below for full method
      setup_project

      # `result_path` is a helper method that runs the job in the now-set-up
      #   context state, and returns its output file path
      result_a = result_path(:places__norm_unique_cleaned)
      expected_a = File.join(
        Tms.datadir, "test", "places_norm_unique_cleaned_N0.csv"
      )

      result_b = result_path(:places__cleaned_unique)
      expected_b = File.join(
        Tms.datadir, "test", "places_cleaned_unique_N0.csv"
      )

      result_c = result_path(:places__worksheet)
      expected_c = File.join(
        Tms.datadir, "to_client", "places_worksheet_N1.csv"
      )

      # The actual tests
      expect(result_a).to match_csv(expected_a)
      expect(result_b).to match_csv(expected_b)
      expect(result_c).to match_csv(expected_c)

      # Remove this file, which wouldn't be handled by `clear_working`
      FileUtils.rm(result_c)

      # Probably overkill to do this at the beginning and end of the test,
      #   but I don't remember what I was running into with these.
      reset_configs
    end
  end

  # Same basic pattern as above, but we are setting up the state where
  #   we've provided the first worksheet and the client has returned it
  #   completed.
  context "when initial cleanup returned", :clean1 do
    it "transforms as expected" do
      reset_configs
      clear_working
      copy_from_test("places_norm_unique_N0.csv")
      Tms::Places.config.returned = [
        "places_worksheet_ret_N1.csv"
      ]
      Tms::Places.config.worksheets = [
        "places_worksheet_N1.csv"
      ]
      setup_project

      result_a = result_path(:places__returned_compile)
      expected_a = File.join(
        Tms.datadir, "test", "places_returned_compile_N1.csv"
      )

      result_b = result_path(:places__corrections)
      expected_b = File.join(
        Tms.datadir, "test", "places_corrections_N1.csv"
      )

      result_c = result_path(:places__norm_unique_cleaned)
      expected_c = File.join(
        Tms.datadir, "test", "places_norm_unique_cleaned_N1.csv"
      )

      result_d = result_path(:places__cleaned_unique)
      expected_d = File.join(
        Tms.datadir, "test", "places_cleaned_unique_N1.csv"
      )

      result_e = result_path(:places__worksheet)
      expected_e = File.join(
        Tms.datadir, "to_client", "places_worksheet_N2.csv"
      )

      expect(result_a).to match_csv(expected_a)
      expect(result_b).to match_csv(expected_b)
      expect(result_c).to match_csv(expected_c)
      expect(result_d).to match_csv(expected_d)
      expect(result_e).to match_csv(expected_e)

      FileUtils.rm(result_e)
      reset_configs
    end
  end

  # Here we are testing the generation of a new worksheet after an
  #   initial round of cleanup was completed and a fresh dataset was
  #   provided. Is previous client work preserved as expected? Is the
  #   :to_review field populated as expected only for new values?
  context "when fresh data after initial cleanup", :fresh1 do
    it "transforms as expected" do
      reset_configs
      clear_working
      copy_from_test("places_orig_normalized_N2.csv")
      Tms::Places.config.returned = [
        "places_worksheet_ret_N1.csv"
      ]
      Tms::Places.config.worksheets = [
        "places_worksheet_N1.csv"
      ]
      setup_project

      result_a = result_path(:places__norm_unique)
      expected_a = File.join(
        Tms.datadir, "test", "places_norm_unique_N2.csv"
      )

      # :places__returned_compile should be identical to :clean1
      # :places__corrections should be identical to :clean1

      result_b = result_path(:places__norm_unique_cleaned)
      expected_b = File.join(
        Tms.datadir, "test", "places_norm_unique_cleaned_N2.csv"
      )

      result_c = result_path(:places__cleaned_unique)
      expected_c = File.join(
        Tms.datadir, "test", "places_cleaned_unique_N2.csv"
      )

      result_d = result_path(:places__worksheet)
      expected_d = File.join(
        Tms.datadir, "to_client", "places_worksheet_N3.csv"
      )

      expect(result_a).to match_csv(expected_a)
      expect(result_b).to match_csv(expected_b)
      expect(result_c).to match_csv(expected_c)
      expect(result_d).to match_csv(expected_d)

      FileUtils.rm(result_d)
      reset_configs
    end
  end

  # After return of second worksheet
  context "when second round of cleanup", :clean2 do
    it "transforms as expected" do
      reset_configs
      clear_working
      copy_from_test("places_orig_normalized_N2.csv")
      Tms::Places.config.returned = [
        "places_worksheet_ret_N1.csv",
        "places_worksheet_ret_N3.csv"
      ]
      Tms::Places.config.worksheets = [
        "places_worksheet_N1.csv"
      ]
      setup_project

      result_a = result_path(:places__norm_unique)
      expected_a = File.join(
        Tms.datadir, "test", "places_norm_unique_N2.csv"
      )

      result_b = result_path(:places__returned_compile)
      expected_b = File.join(
        Tms.datadir, "test", "places_returned_compile_N3.csv"
      )

      result_c = result_path(:places__corrections)
      expected_c = File.join(
        Tms.datadir, "test", "places_corrections_N3.csv"
      )

      result_d = result_path(:places__norm_unique_cleaned)
      expected_d = File.join(
        Tms.datadir, "test", "places_norm_unique_cleaned_N3.csv"
      )

      result_e = result_path(:places__cleaned_unique)
      expected_e = File.join(
        Tms.datadir, "test", "places_cleaned_unique_N3.csv"
      )

      expect(result_a).to match_csv(expected_a)
      expect(result_b).to match_csv(expected_b)
      expect(result_c).to match_csv(expected_c)
      expect(result_d).to match_csv(expected_d)
      expect(result_e).to match_csv(expected_e)

      # FileUtils.rm(result_d)
      reset_configs
    end
  end
end
~~~~

##### `setup_project` method from `./spec/helpers.rb`
~~~~ruby
def setup_project(dependent_config = nil)
  # Special csvopts for TMS to clear out literal "NULL" strings that
  #   indicate empty fields in tables extracted from the database
  # OVERRIDE KIBA::EXTEND'S DEFAULT OPTIONS
  Kiba::Extend.config.csvopts = {encoding: "utf-8",
                                 headers: true,
                                 header_converters: [:symbol, :downcase],
                                 converters: %i[stripplus nulltonil]}

  Kiba::Extend.config.pre_job_task_mode = :no

  # By the time tests are being run, the project code has already been
  #   loaded. This means the registry has already been generated based on
  #   the real current state of the project. So we clear it out. This
  #   could now be replaced by Kiba::Extend.reset_registry
  registry = Kiba::Extend::Registry::FileRegistry.new
  Kiba::Extend.config.registry = registry
  Kiba::Tms.config.registry = Kiba::Extend.registry

  # This is related to some complicated stuff I'd do differently now,
  #   mostly related to clearing out default system values that don't
  #   mean anything, so we can identify fields that are actually
  #   unused by the client, and report on them. And ensure those fields
  #   are all still empty when the client provides updated data.
  set_auto_derived_initial_config

  # Then we get to manually configuring settings related to the assumptions
  #   made in the tests and how the test files were generated.
  # Setup kiba-tms options
  Kiba::Tms::ObjGeography.config.empty_fields = {
    concession: [nil, "", "0", ".0000"],
    easting: [nil, "", "0", ".0000"],
    elevation: [nil, "", "0", ".0000"],
    excavation: [nil, "", "0", ".0000"],
    latitude: [nil, "", "0", ".0000"],
    longitude: [nil, "", "0", ".0000"],
    lot: [nil, "", "0", ".0000"],
    mapreferencenumber: [nil, "", "0", ".0000"],
    northing: [nil, "", "0", ".0000"],
    regionalcorp: [nil, "", "0", ".0000"],
    subcontinent: [nil, "", "0", ".0000"],
    utm: [nil, "", "0", ".0000"],
    villagecorporation: [nil, "", "0", ".0000"]
  }
  Kiba::Tms::ObjGeography.config.controlled_types = :all
  Kiba::Tms::Places.config.hierarchy_fields =
    %i[city state country nation continent]
  Kiba::Tms::Places.config.misc_note_patterns =
    [/ *\((?:\?--|)see GR\) *$/,
      / *\((?:former|panorama|per artist|from literary reference)\)$/i,
      / *\((?:from book.*|formerly|see remarks|stereoview)\)$/i,
      / *\((?:see notes)\)$/i,
      / *\((?:current|earlier|former|previous) name\)$/i,
      /(?:; former name|see remarks)/i]

  # Load some complicated settings that depend on settings that need to be
  #   set up first
  Kiba::Tms.meta_config

  # More stuff replaced by Kiba::Extend.reset_registry
  Kiba::Tms.finalize_config
  Kiba::Tms::RegistryData.register
  Kiba::Tms.registry.transform
  Kiba::Tms.registry.freeze
end
~~~~
