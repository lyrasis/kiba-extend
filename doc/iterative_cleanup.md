# Using the `IterativeCleanup` mixin (added in v4.0.0)

"Iterative cleanup" means the client may provide the worksheet more
than once, or that you may need to produce a fresh worksheet for the
client after a new database export is provided.

There is no reason you can't use the pattern for expected one-round
cleanup. How often does one round of cleanup turn into more, after
all?

## Examples

[kiba-extend-project](https://github.com/lyrasis/kiba-extend-project)
has been updated to reflect usage of the `IterativeCleanup` mixin.

Refer to todo:link Kiba::Tms::AltNumsForObjTypeCleanup as an example
  config module extending this mixin module in a simple way. See
  todo:link Kiba::Tms::PlacesCleanupInitial for a more complex usage
  with default overrides and custom pre/post transforms.

## Project setup assumptions

Your project must follow some setup/configuration conventions in order
  to use this mixin:

### Each cleanup process must be configured in its own config module

A config module is a Ruby module that responds to `:config`.

Extending `Dry::Configurable` adds a `config` method to a module:

```ruby
module Project::NameCategorization
  module_function
  extend Dry::Configurable
end
```

Or you can manually define a `config` class method on the module:

```ruby
module Project::PersonCleanup
  module_function

  def config
    true
  end
end
```

### `Kiba::Extend` `config_namespaces` setting must be set from your project

After your project's base file has called the project's `loader`, it
must set the `Kiba::Extend.config.config_namespaces` setting.

This setting lists the namespace(s) where your config modules live.

In most of my projects, all of my config modules are in one namespace.
For example, for the above project, I would add:

```ruby
Kiba::Extend.config.config_namespaces = [Project]
```

Note that the setting takes an array, so you can list multiple
namespaces if you have organized your project differently and your
configs are not all in one namespace. For example, a migration for a
Tms client may have client specific cleanups in the client-specific
migration code project (config namespace: `TmsClientName`). That code
project will make use of the kiba-tms application, which also defines
cleanup configs in the namespace `Kiba::Tms`. Such a project would do
this at the bottom of `lib/tms_client_name.rb`:

```ruby
Kiba::Extend.config.config_namespaces = [Kiba::Tms, TmsClientName]
```

### Add cleanup job registration to your `RegistryData` registration method

Add the following to `RegistryData.register` (or whatever method
triggers the registration of all your jobs):

```ruby
Kiba::Extend::Utils::IterativeCleanupJobRegistrar.call
```

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

- Represent the original values of the editable fields of the
  cleanup worksheet, so that we can identify rows where the client
  made changes
- Allow multiple rows corrected to the same value to be collapsed
  to one row for future iterations of review/cleanup

It follows that the `IterativeCleanup`-related `fingerprint_fields` used to create `:clean_fingerprint` should include all fields included in the worksheet that:

- you expect to be edited
- combine to uniquely identify a row (for example, if you have an `:orig_name` column with the original data, and a separate, initially blank `:corrected_name` column, you'd need to include both fields in `fingerprint_fields`, since the initially blank value of `corrected_name` does not uniquely identify the rows.)

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

Defines settings used in `KeProject::Places::PrepForCleanup` job (and, presumably, in a real project, other jobs.

Note that the value of `KeProject::Places.fingerprint_fields` is different from the value of `KeProject::PlacesCleanup.fingerprint_fields`. This works for the reasons outlined in the [`:fingerprint` vs. `:clean_fingerprint` section](#fingerprints).

### places cleanup config notes

Note that the value of `KeProject::Places.fingerprint_fields` is different from the value of `KeProject::PlacesCleanup.fingerprint_fields`. This works for the reasons outlined in the [`:fingerprint` vs. `:clean_fingerprint` section](#fingerprints).

#### Required before extending `IterativeCleanup`: `base_job`

See [the description of base_job below](#basejob).

#### Required before extending `IterativeCleanup`: `job_tags`

Allows retrieval and running of jobs via `thor jobs:tagged`, `thor jobs:tagged_or`, and `thor jobs:tagged_and` commands.

The cleanup config module must define either a `job_tags` setting or method before calling `extend Kiba::Extend::Mixins::IterativeCleanup`.

If you do not wish to set tags, have the `job_tags` setting/method return an empty Array.

#### Required before extending `IterativeCleanup`: `worksheet_add_fields`

Columns/fields that will be added in the cleanup process, usually to allow client to fill in values.

In the first iteration of cleanup, these columns are blank. If these fields are also included in `fingerprint_fields`, their corrected values in returned worksheets will be merged into the migration and retained in subsequent worksheets.

#### Required before extending `IterativeCleanup`: `fingerprint_fields`

The fields that will be hashed into the `:clean_fingerprint` value. See the [`:fingerprint` vs. `:clean_fingerprint` section](#fingerprints) for more detail.

Usually you will want to include any `worksheet_add_fields`, plus any other fields that, in combination with the `worksheet_add_fields`, yield the full corrected value for the row.

#### Required before extending `IterativeCleanup`: `fingerprint_fields`

## The process

Here is the default iterative cleanup process, represented in a
flowchart. There's also a [higher-resolution PDF
version](https://github.com/lyrasis/kiba-extend/blob/main/doc/iterative_cleanup_flowchart.pdf),
and [the raw Mermaid source of the
flowchart](https://github.com/lyrasis/kiba-extend/blob/main/doc/iterative_cleanup_flowchart.mmd).
The steps and settings are explained textually below the flowchart.

![Flowchart](https://github.com/lyrasis/kiba-extend/blob/main/doc/iterative_cleanup_flowchart.png?raw=true)

The following explanation uses the demonstration places cleanup in
kiba-extend-project as its main example.

### base_job {#basejob}

This job is created outside the iterative cleanup process, and serves
as the base and starting point for a cleanup process.

The full registry entry key (e.g. `places__prep_for_cleanup`) must be
set as the `base_job` setting in a cleanup config module prior to
extending that module with {Kiba::Extend::Mixins::IterativeCleanup}.
See
`[lib/ke_project/places_cleanup.rb](https://github.com/lyrasis/kiba-extend-project/blob/main/lib/ke_project/places_cleanup.rb)`.

**IMPORTANT: This job's output must include a field which combines/identifies the
original values that may be affected by the cleanup process.** The
default expectation is that this field is named `:fingerprint`, but this
can be overridden by defining a custom `orig_values_identifier` method
in the extending module after extension. This field is used as a
matchpoint for merging cleaned up data back into the migration, and
identifying whether a given value in subsequent worksheet iterations
has been previously included in a worksheet.
