<!--
# @markup markdown
# @title Troubleshooting
-->

# Troubleshooting

## `MissingDependencyError` when all dependencies are set up as expected

Usually the cause of a `MissingDependencyError` is that a table required in some later job ends up having no rows, and thus is not written out.

So jobs are all set up properly, but some expected output file doesn't exist.

When there are no rows to write out to a Destination, we don't even know what the expected headers would have been in order to write a headers-only CSV.

At some point I plan to test whether jobs with no output can be made to just create a blank file, and whether that causes dependent jobs to fail in other ways.

For now, as of 3.3.0.150, you defend against this using the `Kiba::Extend::Job.output?` method to dynamically select only jobs having output for use as sources or lookups.

## "WARNING: unable to load thorfile ... Expected file ... to define constant ... but didn't" error

Example error text:

```
WARNING: unable to load thorfile "/Users/you/projectname/Thorfile": expected file /Users/you/projectname/lib/project/jobs/name_cleanup_prep/person_names.rb to define constant Project::Jobs::NameCleanupPrep::PersonNames, but didn't
```

This is related to autoloading via zeitwerk and the default assumptions made by that tool. See [The Idea: File Paths Match Constant Paths](https://github.com/fxn/zeitwerk?tab=readme-ov-file#the-idea-file-paths-match-constant-paths).

The usual culprits causing this are:

- Naming the file `person_names.rb` but naming the constant defined in the file `Personnames` (should be `PersonNames`)
- Opposite of above: naming the file `personnames.rb` and the constant defined in the file `PersonNames` (should be `Personnames`)
- Mismatch of file path hierarchy and constant hierarchy. For example, having file path `/Users/you/projectname/lib/project/jobs/name_cleanup_prep/person_names.rb` but the following in your file:

```
module Project
  module NameCleanupPrep
    module PersonNames
	end
  end
end
```

The "jobs" level of file hierarchy is expected to be represented in your module namespace hierarchy, like:

```
module Project
  module Jobs
    module NameCleanupPrep
      module PersonNames
	  end
    end
  end
end
```

Zeitwerk provides ways to override almost all of this default behavior via inflectors, namespace collapsing, and techniques. See its very long README (linked above) for details. However, it's generally easier in most projects to follow the default convention (pretty simple once you are used to it) and reap the benefits of never having to `require_relative` anything ever again (a huge pain if you move files around or rename things).

**Namespace collapsing example:** migration-cspace-csu-base organizes its namespaced job-category module configs in `/lib/kiba/csu/config`, but collapses the config directory. See `setup_loader` in [`/lib/kiba/csu.rb`](https://github.com/dts-hosting/migration-cspace-csu-base/blob/main/lib/kiba/csu.rb). This means I can have `/lib/kiba/csu/config/cleanup_prep.rb` defining `Kiba::Csu::CleanupPrep` config module.

**Inflections example:** kiba-tms defines inflectors for dealing with some TMS tables. Generally, kiba-tms defines a config module per TMS table. For clarity, the names of the tables and the config module constants should match. For a table like `ClassificationXRefs`, I would be annoyed to have to name my file `classification_x_refs.rb` (especially since there are other tables named like: `ConXrefs`). So I added an inflector to handle this in `setup_loader` method in `/lib/kiba/tms.rb`.
