<!--
# @markup markdown
# @title kiba-extend Concepts
-->

* TOC
{:toc}

## Glossary {#glossary}

File registry key
: Synonym for `Full job key`.

Full job key
: A Ruby Symbol built from `FileRegistry` namespace (if used) and registry entry name, separated by the value of `Kiba::Extend.registry_namespace_separator` (defaults to `__` (two underscores)). Examples: With namespace: `:namespace__entry_name`; No namespace: `:unnamespaced_entry_name`.

Job definition module
: Ruby Module in your project that defines: (1) source, destination, and optional lookups for the job; and (2) the data transformations for the job. See [Kiba::Extend::Jobs](https://lyrasis.github.io/kiba-extend/Kiba/Extend/Jobs.html).

## Typology of kiba-extend projects {#projecttypes}

### Oneoff/direct

This project uses kiba-extend directly and is self-contained. [kiba-extend-project](https://github.com/lyrasis/kiba-extend-project) is an example of a oneoff/direct project.

### Parent

One powerful way of using kiba-extend is to create an "abstract" parent ETL project.

A parent project handles the general logic of transforming data from a specific source system into the format required by a given target system.
For example, if you frequently need to migrate data from OldSystem to NewSystem, you may create a parent OldSystem kiba-extend project that can handle the general structure of data out of OldSystem and its transformation, such as:

- what the source data files are;
- hardcoded enum values that need to be replaced in the data;
- what standard data preprocessing needs to be done;
- how to merge data from lookup tables; and
- remapping the data into the "shape" you need it to be in for NewSystem.

All the specifics that may change per specific instance of such a project are defined as configuration settings in the parent project.
For instance one OldSystem user may only want to migrate records with `active=true` values to NewSystem, while another may wish to also migrate all records regardless of `active` status.

In this case, you might define a `migrate_inactive` setting in the parent project.

### Child

A project for a specific client or data set, based on a Parent project

You set the client-specific values for the configuration settings you defined in the parent project (such as `migrate_inactive`) for each client in the child projects.

Client-specific jobs and transforms can also be defined in child projects as needed.

Theoretically, you can also have grandchild projects and even deeper projects.
However, those would get pretty difficult to understand and manage.

## Assumptions and concepts used in libraries used by `kiba-extend` {#other-libraries}

### Folder structure, file names, module/class name constants defined in files {#zeitwerk}

`kiba-extend` uses [zeitwerk](https://github.com/fxn/zeitwerk) to automatically handle code loading, so you don't have to manually enter `require_relative` every time you refer to code in another file. (The manual way is tedious and horrible if you end up renaming files or moving them around).

zeitwerk makes some strong default assumptions about folder hierarchies, file names, and constant names/namespace hierarchies defined in your code. See [The Idea: File Paths Match Constant Paths](https://github.com/fxn/zeitwerk?tab=readme-ov-file#the-idea-file-paths-match-constant-paths).

These align with the [One Class per File](https://rubystyle.guide/#one-class-per-file) rule in the [Ruby Style Guide](https://rubystyle.guide), as well as the other rules in the guide pertaining to [Naming Conventions](https://rubystyle.guide/#naming-conventions).

Zeitwerk provides ways to override almost all of its default assumptions via inflectors, namespace collapsing, and techniques. See its very long README (linked above) for details. However, it's generally easier in most projects to follow the default convention (pretty simple once you are used to it).

**Namespace collapsing example:** migration-cspace-csu-base organizes its namespaced job-category module configs in `/lib/kiba/csu/config`, but collapses the config directory. See `setup_loader` in [`/lib/kiba/csu.rb`](https://github.com/dts-hosting/migration-cspace-csu-base/blob/main/lib/kiba/csu.rb). This means I can have `/lib/kiba/csu/config/cleanup_prep.rb` defining `Kiba::Csu::CleanupPrep` config module.

**Inflections example:** kiba-tms defines inflectors for dealing with some TMS tables. Generally, kiba-tms defines a config module per TMS table. For clarity, the names of the tables and the config module constants should match. For a table like `ClassificationXRefs`, I would be annoyed to have to name my file `classification_x_refs.rb` (especially since there are other tables named like: `ConXrefs`). So I added an inflector to handle this in `setup_loader` method in `/lib/kiba/tms.rb`.

### Config settings via `dry-configurable` {#dry-configurable}

`kiba-extend` and projects based on it make heavy use of the `dry-configurable` gem to add flexible but safe config settings to control application behavior.

This is particularly heavily used in "abstract" `kiba-extend` projects like `kiba-tms` or `migrations-cspace-csu-base` which are used as middle layers between `kiba-extend` and individual client projects.

However, even for one-off projects, it can be convenient to add settings for values used across your project to the main project module definition.

`dry-configurable` is pretty simple. [Its documentation](https://dry-rb.org/gems/dry-configurable/main/) is only two pages, though it leaves some important things out, such as:

- Values assigned to a setting (including) `default` value must respond to `#freeze` method. You generally cannot calculate the `default` value of a setting. For example, this will raise an error:

~~~
setting :indemnity_fields,
  default: fields.select { |f| f.to_s.start_with?("ind") },
  reader: true
~~~

- If you need to dynamically set the default value of a setting, you must provide a custom constructor instead:

~~~
setting :indemnity_fields,
  default: %i[],
  reader: true,
  constructor: proc { fields.select { |f| f.to_s.start_with?("ind") } }
~~~
A constructor is always a Proc or Lambda returning a value that can be frozen.

The first time `YourApp.indemnity_fields` is called from elsewhere in your code, the constructor code is called and the value is set to its result and frozen.

Here is a more complex example defining the `:note_fields` setting for constituent addresses in kiba-tms. It is slightly modified from reality to make a better example:

~~~
# Which TMS fields should be combined into a single :address_note value
#   per TMS ConAddress row. Conditional logic here automatically includes
#   fields in this setting based on other settings.
setting :note_fields,
  default: %i[addressnote],
  reader: true,
  constructor: ->(value) {
    value << :remarks if migrate_remarks
    value << :addresstypenote if Tms::AddressTypes.used? &&
      address_type_handling == :note
    value << :addressdates if dates_note
    value << :active if migrate_inactive && active_note
    %w[billing mailing shipping].each do |type|
      value << type.to_sym if send("#{type}_note".to_sym)
    end
    value
  }
~~~

The `->(value)` is creating the constructor as a Lambda and passing in the setting's `default` value as `value`. The `:addressnote` field is always treated as a note field from this table. Other fields get added to this list based on the specified criteria.

- The value of a setting defined by a constructor is set the first time the setting is called/used in the application. It is NOT recalculated on additional calls of the setting.

- The value of a setting can be overwritten at any time from anywhere. This is the principle on which kiba-tms and migrations-cspace-csu-base are based. Much of the code in a client project is dedicated to defining the correct setting values for the individual project. See everything below line 41 [here](https://github.com/dts-hosting/migration-cspace-az_ccp/blob/main/lib/az_ccp.rb).

- Setting values are not actually frozen until they are called. This is what allows us to do the following in a kiba-tms individual client project's main config:

~~~
Kiba::Tms::Exhibitions.delete_fields << :lightexpdaysperweek
Kiba::Tms::Exhibitions.delete_fields << :lightexphoursperday
~~~

The kiba-tms and client project main configs are read in/defined before any thing else happens, so we can add some fields to be removed when we process the Exhibitions table.

If anything else had called `Kiba::Tms::Exhibitions.delete_fields` before this point, we'd get an error when we tried to do this.

- When the value of a setting is overwritten, it looks like you can set the value to something calculated without using a contructor:

~~~
 Kiba::Tms::Exhibitions.config.post_shape_xforms = Kiba.job_segment do
    transform Merge::ConstantValueConditional,
      fieldmap: {exhibitionstatus: "Facility report received",
                 exhibitionstatusnote: "yes"},
      condition: ->(row) do
        !row[:text_entry].blank?
      end
    transform Delete::Fields, fields: :text_entry
  end
~~~

Whatever's after the `=` is evaluated first and the result of that evaluation is set as the settingvalue. The result of the `Kiba.job_segment` block is a `String`, so it can be a setting value.

## Thinking in reusable transformation steps

(todo)
