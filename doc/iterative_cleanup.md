# Using the `IterativeCleanup` mixin (added in v4.0.0)

"Iterative cleanup" means the client may provide the worksheet more
than once, or that you may need to produce a fresh worksheet for the
client after a new database export is provided.

There is no reason you can't use the pattern for expected one-round
cleanup. How often does one round of cleanup turn into more, after
all?

## Examples

[kiba-extend-project](https://github.com/lyrasis/kiba-extend-project)
has been updated to reflect usage of the `IterativeCleanup` mixin. If
you have an existing project based off `kiba-extend-project`, [this
diff](https://github.com/lyrasis/kiba-extend-project/compare/pre-iterative-cleanup...demo-iterative-cleanup)
might help identify what you need to add to your project to use
`IterativeCleanup`.

Refer to
  [Kiba::Tms::AltNumsForObjTypeCleanup](https://github.com/lyrasis/kiba-tms/blob/main/lib/kiba/tms/alt_nums_for_obj_type_cleanup.rb)
  as an example config module extending `IterativeCleanup` in a simple
  way. See
  [Kiba::Tms::PlacesCleanupInitial](https://github.com/lyrasis/kiba-tms/blob/main/lib/kiba/tms/places_cleanup_initial.rb)
  for a more complex usage with default overrides and custom pre/post
  transforms.

## Project setup assumptions

Your project must follow some setup/configuration conventions in order
  to use this mixin:

### Each cleanup process must be configured in its own config module

A config module is a Ruby module that [responds to](https://ruby-doc.org/core-3.1.0/Object.html#method-i-respond_to-3F) `:config`.

Extending `Dry::Configurable` adds a `config` method to a module:

~~~ ruby
module Project::NameCategorization
  module_function
  extend Dry::Configurable
end
~~~

Or you can manually define a `config` class method on the module:

~~~ ruby
module Project::PersonCleanup
  module_function

  def config
    true
  end
end
~~~

### `Kiba::Extend` `config_namespaces` setting must be set from your project

After your project's base file has called the project's `loader`, it
must set the `Kiba::Extend.config.config_namespaces` setting.

This setting lists the namespace(s) where your config modules live.

In most of my projects, all of my config modules are in one namespace.
For example, for the above project, I would add:

~~~ ruby
Kiba::Extend.config.config_namespaces = [Project]
~~~

Note that the setting takes an array, so you can list multiple
namespaces if you have organized your project differently and your
configs are not all in one namespace. For example, a migration for a
Tms client may have client specific cleanups in the client-specific
migration code project (config namespace: `TmsClientName`). That code
project will make use of the kiba-tms application, which also defines
cleanup configs in the namespace `Kiba::Tms`. Such a project would do
this at the bottom of `lib/tms_client_name.rb`:

~~~ ruby
Kiba::Extend.config.config_namespaces = [Kiba::Tms, TmsClientName]
~~~

### Add cleanup job registration to your `RegistryData` registration method

Add the following to `RegistryData.register` (or whatever method
triggers the registration of all your jobs):

~~~ ruby
Kiba::Extend::Utils::IterativeCleanupJobRegistrar.call
~~~

This line should be added before any `registry.transform`,
`registry.freeze`, or `registry.finalize` methods.

### `config_namespaces` setting is populated before `RegistryData` registration

Calling `RegistryData.register` (or whatever method triggers the
registration of all your jobs) must be done ***after*** the
`config_namespaces` are set.

## Setup of an individual iterative cleanup process

The following explanation uses the demonstration places cleanup in
[kiba-extend-project](https://github.com/lyrasis/kiba-extend-project)
as its main example.

- [`lib/ke_project/places_cleanup.rb`](https://github.com/lyrasis/kiba-extend-project/blob/main/lib/ke_project/places_cleanup.rb) -
  config module for the iterative cleanup process
- [`lib/ke_project/places.rb`](https://github.com/lyrasis/kiba-extend-project/blob/main/lib/ke_project/places.rb) -
  config module for general places processing, including generation of
  the cleanup `base_job`

### `:fingerprint` vs. `:clean_fingerprint` and their functions in an iterative cleanup process {#fingerprints}

The `fingerprint_fields` setting required in a cleanup config module
is only used *inside the iterative cleanup process* to add and decode
`:clean_fingerprint` values.

In the iterative cleanup process, the function of `:clean_fingerprint`
is:

- Represent the original values of the editable fields of the cleanup
  worksheet, so that we can identify rows where the client made
  changes
- Allow multiple rows corrected to the same value to be collapsed to
  one row for future iterations of review/cleanup

It follows that the `IterativeCleanup`-related `fingerprint_fields`
used to create `:clean_fingerprint` should include all fields included
in the worksheet that:

- you expect to be edited
- combine to uniquely identify a row (for example, if you have an
  `:orig_name` column with the original data, and a separate,
  initially blank `:corrected_name` column, you'd need to include both
  fields in `fingerprint_fields`, since the initially blank value of
  `corrected_name` does not uniquely identify the rows.)

The file associated with the iterative cleanup process' `base_job` is
expected to include a `:fingerprint` field by default. The name of
this field can be changed in the cleanup config. The function of this
field in the iterative cleanup is:

- In subsequent iterations, determine if a row in the worksheet has
  been seen before or needs to be marked for review
- Each cleaned row keeps track of the `:fingerprint` values of the
  original rows that have been collapsed/changed into the clean row

The complete difference in function for `:fingerprint` and
`:clean_fingerprint` is why it is possible to override
`orig_values_identifier` in your cleanup config module after extending
`IterativeCleanup`.

The `KeProject::PlacesCleanup` process could probably work just fine
by overriding `orig_values_identifier` to be `:place`, and not adding
a `:fingerprint` field in
[`KeProject::Jobs::Places::PrepForCleanup`](https://github.com/lyrasis/kiba-extend-project/blob/main/lib/ke_project/jobs/places/prep_for_cleanup.rb).

### places config notes

Defines settings used in `KeProject::Places::PrepForCleanup` job (and,
presumably, in a real project, other jobs.

Note that the value of `KeProject::Places.fingerprint_fields` is
different from the value of
`KeProject::PlacesCleanup.fingerprint_fields`. This works for the
reasons outlined in the [`:fingerprint` vs. `:clean_fingerprint`
section](#fingerprints).

### places cleanup config notes

#### Required before extending `IterativeCleanup`: `base_job`

This job is created outside the iterative cleanup process, and serves
as the base and starting point for a cleanup process.

The full registry entry key (e.g. `places__prep_for_cleanup`) must be
set as the `base_job` setting in a cleanup config module prior to
extending that module with {Kiba::Extend::Mixins::IterativeCleanup}.
See
[`lib/ke_project/places_cleanup.rb`](https://github.com/lyrasis/kiba-extend-project/blob/main/lib/ke_project/places_cleanup.rb).

**IMPORTANT: This job's output must include a field which
combines/identifies the original values that may be affected by the
cleanup process.** The default expectation is that this field is named
`:fingerprint`, but this can be overridden by defining a custom
`orig_values_identifier` method in the extending module after
extension. This field is used as a matchpoint for merging cleaned up
data back into the migration, and identifying whether a given value in
subsequent worksheet iterations has been previously included in a
worksheet.

#### Required before extending `IterativeCleanup`: `fingerprint_fields`

The fields that will be hashed into the `:clean_fingerprint` value.
See the [`:fingerprint` vs. `:clean_fingerprint`
section](#fingerprints) for more detail.

Usually you will want to include any `worksheet_add_fields`, plus any
other fields that, in combination with the `worksheet_add_fields`,
yield the full corrected value for the row.

#### Optional default method overrides

There are a number of overrideable methods. They are well-documented at
{Kiba::Extend::Mixins::IterativeCleanup}. Look for the list under
"Methods that can be optionally overridden in extending module".

The ones used in the demo config are listed below. Look at the documentation linked above for the full list.

##### `worksheet_add_fields`

I want clients to be able to remove things like "near" and "(?)" from
these place terms, recording proximity and uncertainty information in
separate fields. So I add those fields for use.

##### `job_tags`

Allows retrieval and running of jobs via `thor jobs:tagged`, `thor
jobs:tagged_or`, and `thor jobs:tagged_and` commands.

##### `cleanup_base_name`

This is an important one to understand. Our cleanup config module name
is `PlacesCleanup`, so by default, `cleanup_base_name` will be set to
`"places_cleanup"`.

This is used as the namespace for registering the jobs associated with
the cleanup process, for example `:places_cleanup__worksheet`.

You can override this if you want.

##### Custom transforms!

See {Kiba::Extend::Mixins::IterativeCleanup::Jobs} for documentation,
and the `kiba-tms`
[`PlacesInitialCleanup`](https://github.com/lyrasis/kiba-tms/blob/main/lib/kiba/tms/places_cleanup_initial.rb)
config module for use examples.

## The process

Here is the default iterative cleanup process, represented in a
flowchart. There's also a [higher-resolution PDF
version](https://github.com/lyrasis/kiba-extend/blob/main/doc/iterative_cleanup_flowchart.pdf),
and [the raw Mermaid source of the
flowchart](https://github.com/lyrasis/kiba-extend/blob/main/doc/iterative_cleanup_flowchart.mmd).
The steps and settings are explained textually below the flowchart.

![Flowchart](https://github.com/lyrasis/kiba-extend/blob/main/doc/iterative_cleanup_flowchart.png?raw=true)

Right now, the best place to step through and check out the processing
in a detailed way is to look at the following in the `kiba-tms`
repository:

- [`PlacesInitialCleanup`](https://github.com/lyrasis/kiba-tms/blob/main/lib/kiba/tms/places_cleanup_initial.rb)
  and [its detailed
  tests](https://github.com/lyrasis/kiba-tms/blob/main/spec/kiba/tms/places_cleanup_initial_spec.rb):
 - generation of initial worksheet (i.e. "when no cleanup done")
 - merge of corrected data and generation of a second worksheet after
   first round of cleanup is returned (i.e. "when initial cleanup
   returned")
 - after a new database export is received after an initial round of
   cleanup has been done (i.e. "when fresh data after initial
   cleanup") - all previous cleanup retained; cleanup rows linked to
   now-deleted database data no longer appear; any new values in
   cleanup worksheet generated at this point get flagged "to_review"
 - verification of everything after worksheet based on fresh data is
   returned, including "final" job (i.e. "when second round of
   cleanup")

### BaseJobCleaned `:cleanup_base_name__base_job_cleaned` {#basejobcleaned}

#### If no cleanup worksheets returned

Adds any `worksheet_add_fields` you have specified.

Adds `:clean_fingerprint` field.

#### If any cleanup worksheets returned

Adds any `worksheet_add_fields` you have specified.

Merges corrections. See [Corrections](#corrections) for details on how
corrections are prepared for merge back into original data.

Adds `:clean_fingerprint` field.

### CleanedUniq `:cleanup_base_name__cleaned_uniq` {#cleaneduniq}

Starts with [BaseJobCleaned](#basejobcleaned) output.

Deletes `:fingerprint` (or your custom `orig_values_identifier`) and
any custom `collate_fields` you specified.

Deduplicates on `:clean_fingerprint` field values. Now if four rows
for "North Carolina", "NC", "N.C.", and "N. Carolina" have all been
changed to "North Carolina", we only have one row for "North
Carolina".

Re-merges in the collate fields (including
`orig_values_identifier`/`:fingerprint` field) as multi-valued fields
(separated by `collation_delim`). This also pluralizes collate field
names that don't start with "s". So our one row for "North Carolina"
will have now have a `:fingerprints` field containing 4 fingerprint
values from the 4 original rows.

Once all cleanup is done, this might be the appropriate source job for
further jobs generating unique authority terms.

### Worksheet `:cleanup_base_name__worksheet` {#worksheet}

Starts with [CleanedUniq](#cleaneduniq) output.

See bottom of
[KeProject::PlacesCleanup](https://github.com/lyrasis/kiba-extend-project/blob/main/lib/ke_project/places_cleanup.rb)
for example of recording `provided_worksheets`.

#### If you have recorded no `provided_worksheets`

Rows are just passed through as-is.

#### If you have recorded one or more `provided_worksheets`

Gets a list of known `orig_values_identifier`/`:fingerprint` values in
provided worksheets. It does this by creating and `call`ing a new
{Kiba::Extend::Mixins::IterativeCleanup::KnownWorksheetValues}
instance. This:

- Reads each provided worksheet file
- Gets the `:fingerprints` (or equivalent field) from each row and
  splits the multiple values in a single field
- Compiles and deduplicates all the values

A blank `:to_review` field is added to the worksheet being prepared.

Now for each row we are going to output to *this* worksheet, we:

- Split the values of the `:fingerprints` or equivalent field.
- If **all** the fingerprint values for this row are in the list of
  known values, `:to_review` is left blank.
- Otherwise, `:to_review` is set to "y"

### Worksheet is given to client for completion

At this point, you should record this file in the
`provided_worksheets` setting.

See bottom of
[KeProject::PlacesCleanup](https://github.com/lyrasis/kiba-extend-project/blob/main/lib/ke_project/places_cleanup.rb)
for example of recording `provided_worksheets`.

### Client returns completed (or partially completed) worksheet

At this point, you should record the returned file in the
`returned_files` setting.

See bottom of
[KeProject::PlacesCleanup](https://github.com/lyrasis/kiba-extend-project/blob/main/lib/ke_project/places_cleanup.rb)
for example of recording `returned_files`.

### ReturnedCompiled `:cleanup_base_name__returned_compiled` {#returnedcompiled}

Reads in all rows from `returned_files` as data source. Note that
these must be listed oldest to newest. They are read in as sources in
that order, which is important when we get to merging corrections!

Deletes :to_review field if present.

Runs {Kiba::Extend::Transforms::Fingerprint::FlagChanged}, using
`:clean_fingerprint`. Any custom
`clean_fingerprint_flag_ignore_fields` are ignored. This:

- Adds the decoded (original) fingerprint field values to new fields
  prefixed with "fp_"
- Deletes `:clean_fingerprint` after it has been decoded
- Adds a `:corrected` field.
- Compares each original/fp_ field with its corresponding field in the
  returned file. For rows where any values of the `fingerprint_fields`
  was changed in the returned worksheet, the names of the fields with
  changed values are gathered in the `:corrected` field. For rows with
  no changes, the `:corrected` field is blank.

Deletes the fields prefixed with `:fp_` derived during the
`FlagChanged` process.

Runs {Kiba::Extend::Transforms::Clean::EnsureConsistentFields} to
ensure all rows have the same fields.

### Corrections `:cleanup_base_name__corrections` {#corrections}

Reads in the output of [ReturnedCompiled](#returnedcompiled).

Deletes rows where `:corrections` field is blank.

This leaves just rows where changes were made in a returned worksheet,
from oldest to newest. Order is important!

Because this is an iterative cleanup process, we need to account for
the fact that cleanup done in worksheet #2 may have been done on a
single row that resulted from the cleanup of 4 rows in worksheet #1.
Recall the "North Carolina" example in [CleanedUniq](#cleaneduniq).

For this reason, and because we merge all the corrections, from
oldest-to-newest, back into [BaseJobCleaned](#basejobcleaned) on the
original `:fingerprint`, we run
{Kiba::Extend::Transforms::Explode::RowsFromMultivalField} on that
`:fingerprint` (or equivalent) field.

So, if, in round 1, the `:state` field values "NC", "N.C.", and "N.
Carolina" were all changed to "North Carolina", we have 3 rows in
Corrections output with instructions to merge "North Carolina" into
the `:state` field in rows with matching `:fingerprint` values. (The
4th "North Carolina" row had no change in round 1.)

Now, in round 2, the client noticed that the row with `:state` =
"Ohio" also has `:country` = "USA", and added "USA" as country in the
row for "North Carolina".

The Corrections output is now also going to have 4 rows with
instructions to merge "USA" into the `:country` field in rows with
matching `:fingerprint` values.

So:

<pre>
| country | state          | corrected | fingerprint |
|---------+----------------+-----------+-------------|
|         | North Carolina | state     |           2 |
|         | North Carolina | state     |           3 |
|         | North Carolina | state     |           4 |
| USA     | North Carolina | country   |           1 |
| USA     | North Carolina | country   |           2 |
| USA     | North Carolina | country   |           3 |
| USA     | North Carolina | country   |           4 |
</pre>

For lookup/merge back into [BaseJobCleaned](#basejobcleaned), those
rows are gathered into a hash, with `:fingerprint` as the key:

~~~ ruby
{ 2=>[
  {country: nil, state: "North Carolina", corrected: "state", fingerprint: 2},
  {country: "USA", state: "North Carolina", corrected: "country", fingerprint: 2}
 ]
}
~~~

When the [BaseJobCleaned](#basejobcleaned) merge process hits the row
with `:fingerprint` = 2, it carries out the corrections per row, in
order.

- `row[:state] = "North Carolina"`
- `row[:country] = "USA"`

Why does it do this so inefficiently? Why not just take the last
cleanup row for each fingerprint and replace the field values?

I can't tell you the details why but at some point I tried something
like that and ended up with a mess. That was before I had worked out
some of the stuff with having two separate fingerprints, and there
were other complications with that one. But I worked out this process
and it works, generally, across the board, so I'm leaving it for now.

### Final `:cleanup_base_name__final`

Unless you define custom transforms for this one, it just returns
[BaseJobCleaned](#basejobcleaned) with `:fingerprint` (or your custom
field defined in an override `final_lookup_on_field` method).

Use this as a lookup to get your cleaned data back into other places
in the migration.
