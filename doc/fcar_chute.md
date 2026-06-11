<!--
# @markup markdown
# @title FCAR chute
-->

* TOC
{:toc}

## About FCAR chute {#about}

The FCAR "chute" is an option sequence of FCAR processes that you can configure for your project.

Implementing a chute is particularly useful in the following situations:

- An abstract project where individual client projects will not need to use all the FCAR processes
- One-off client projects with a lot of FCAR processes, that you might not implement in the final expected order.

### Benefits of setting up an FCAR  chute {#benefits}

One main benefit of the chute is that it gives you a `Kiba::Extend::Fcar.final_merged` method that you can use as the Job definition module `source` for the first job that is going to be based on the results of your FCAR phase. You don't need to change the `source` in this job as you add FCAR processes or change their sequence.

The other main benefit of the chute is that you don't need to hard-code the `source` in the Job definition modules that create the `base_job` output for each FCAR process. Instead you can do something like:

~~~ ruby
# frozen_string_literal: true

module Project
  module Jobs
    module FcarPrep
      module NameCatPlus
        module_function

        def job
          Kiba::Extend::Jobs::Job.new(
            files: {
              source:
              Kiba::Extend::Fcar.previous_merged(Project::NameCatPlus),
              destination: :fcar_prep__name_cat_plus
            },
            transformer: xforms
          )
        end
      end
    end
  end
end
~~~

For instance, if our project has:

~~~ ruby
Kiba::Extend::Fcar.config.chute = [
  ItemCount,
  NameSplit,
  NameCatPlus,
  MiscFields
]
~~~

Then, the merged results of the `NameSplit` FCAR process will be used as the source of `Project::Jobs::FcarPrep::NameCatPlus`.

If there are no files recorded in `Project::NameSplit.config.provided_worksheets`, then the `NameSplit` FCAR is still in your chute, but not considered active for your project.

In this case, the merged results of the `ItemCount` FCAR process will be used as the source of `Project::Jobs::FcarPrep::NameCatPlus`.

If `ItemCount` also isn't activated for your project, then the output of the job given as `Kiba::Extend::Fcar.base_source` will be used as the source of `Project::Jobs::FcarPrep::NameCatPlus`.

If you realize that some of the miscellanous fields contain name values that need to be split and categorized, then you can just edit the `chute` setting:

~~~ ruby
Kiba::Extend::Fcar.config.chute = [
  ItemCount,
  MiscFields,
  NameSplit,
  NameCatPlus
]
~~~

### Limitations of FCAR chute {#limitations}

The Fcar chute feature isn't really that intelligent. It will totally let you skip `NameSplit` without doing anything special, if your name fields are all single-value. But it will also let you do `NameCatPlus` without doing `NameSplit` if you do have messily-delimited multi-value name fields.

It is up to you to document the requirements of your chute sequence and make sure you stick to them when implementing projects. One way you can do this is to define your `chute` as a Hash with comments as the values:

~~~ ruby
Kiba::Extend::Fcar.config.chute = {
  "ItemCount" => "standalone; order doesn't really matter",
  "MiscFields" => "potential dependency of name sequence, if any fields are categorized as containing names",
  "NameSplit" => "name sequence; optional first step if multivalue name fields present",
  "NameCatPlus" => "name sequence"
}
~~~

Now, if you do `thor fcar chute` you can see all of this info.

`thor fcar processes` will show you only the names of the active FCAR processes for your project.

## How to implement an FCAR chute {#implement}

### In base config of project: Configure `base_source` and `chute` {#baseconfig}

Set the `base_source` and `chute` settings for your project. This should be done in your main or base config for the project, not any individual project-specific config files. Example:

~~~ ruby
Kiba::Extend::Fcar.config.base_source = :inv_sum__combined
Kiba::Extend::Fcar.config.chute = {
  "Itemandboxcount" => "standalone; I'm sure there's a reason "\
    "this is first but I can't remember what it is",
  "AgencyMuseumNameCleanup" => "sequence; legal-control",
  "CollLevelLegalControl" => "sequence; optional step; legal-control",
  "SiteProjectMapping" => "standalone; client specific, client1",
  "SiteProjectMapping2" => "standalone; client specific, client2",
  "NameSplit" => "sequence; name; DEPENDS ON legal-control "\
    "sequence completion",
  "NameCatPlus" => "sequence; name",
  "County" => "standalone",
  "SiteSplit" => "sequence; site",
  "Site" => "sequence; site"
}
Kiba::Extend::Fcar.config.pending_processes = []
~~~

### In the config files for each FCAR process: define `merge_job` {#mergejob}

This one is important!

This is the job key of the job that produces the full, final version of the affected data with the FCAR process configured in this file merged back in.

This can be defined as a method, or a dry-configurable setting:

~~~ ruby
def merge_job = :name_cat_plus__merged

# OR

setting :merge_job, reader: true, default: :name_cat_plus__merged
~~~

### Dynamically refer to FCAR output in other places {#refer}

To get the job key to be used as a source in the next process in the chute:

~~~ ruby
Kiba::Extend::Fcar.previous_merged(MyProject::County)
~~~

Given the example chute above, this will return the `merge_job` job key of the previous completed process in the chute, or, if there are no completed processes prior to the given one, the value of `Kiba::Extend::Fcar.base_source`.


To get the final output of the entire chute:

~~~ ruby
Kiba::Extend::Fcar.final_merged
~~~

## Using the FCAR chute {#use}

### thor commands {#thor}

`thor fcar chute` displays the entire available chute, with any comments in Hash values.

`thor fcar processes` displays the active FCAR processes for your project, in chute-order.

### Activating an FCAR process for your project {#activate}

An FCAR process in a project's chute is considered active if at least one file is registered in the FCAR process' `provided_worksheets` setting.

But if you haven't produced any worksheets yet, and you try running `thor run job itemandboxcount__worksheet`, you will get an error like:

~~~ bash
JOB FAILED: Error handling source file dependency for
itemandboxcount__base_job_cleaned: Cannot find Kiba::Csu::Itemandboxcount in
configured iterative cleanup chute. If there are not yet any files associated
with the cleanup, you need to add it to Kiba::Extend::Fcar.pending_processes in
the project config
~~~

You need to add the following to your project's main/base config:

### Pending an FCAR process to temporarily activate it {#pend}

~~~ ruby
Kiba::Extend::Fcar.pending_processes << MyProject::Itemandboxcount
~~~

Now you can generate the worksheet. Once the worksheet is finalized and registered in your main/base config as shown below, you can remove the line adding this process to `pending_processes`.

~~~ ruby
MyProject::Itemandboxcount.config.provided_worksheets = [
  "itemandboxcount_worksheet0.csv"
]
~~~
