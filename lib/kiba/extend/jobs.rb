# frozen_string_literal: true

require_relative "jobs/parser"

module Kiba
  module Extend
    # Reusable, composable patterns for defining, running, and testing jobs
    #
    # There are a number of operations that need to be carried out for any job,
    #   depending on the format of the source and destination. For example, for
    #   jobs with CSV input and output, we need to:
    #
    # - Set up the sources, destinations, and lookups
    # - Create @srcrows and @outrows instance variables
    # - Convert CSV rows to hashes (initial transforms) prior to executing other
    #   transformation logic
    # - Convert hashes back to CSV rows after executing transformations
    # - Calling any defined postprocessing
    #
    # Most of this logic never changes for jobs with the same
    #   input/output formats, so it is extracted here. This allows us
    #   to simplify the job definition modules we write in a given
    #   project.
    #
    # ## Defining jobs in your project
    #
    # The simplest job definition module will consist only of a `:job`
    #   method, which initializes the appropriate Kiba::Extend::Jobs
    #   job class for the planned input/output formats.
    #
    # Creating a new Kiba::Extend::Jobs class requires two arguments be
    #   provided: `files` and `transformer`
    #
    # ### `files` argument
    #
    # `files` is the configuration of destination, source, and lookup
    #   files the job will use. It is a Hash with two required keys:
    #   `:source` and `:destination`. If the transformation logic refers
    #   to any lookup jobs, a `:lookup` key can be included.
    #
    # The values of `:source`, `:destination`, and `:lookup` must be
    #   full namespaced job keys that are defined in your registry.
    #   You can provide an array of job keys or a single job key
    #   Symbol. Note that, if you provide more than one `:destination` job key,
    #   only the first will be used. A given job can only write to a single
    #   destination.
    #
    # ~~~
    # { source: [:ns__job1],
    #    destination: [:ns__job2, :ns__job3],
    #    lookup: [:ns__job4, :ns__job5]
    # }
    # ~~~
    #
    # Is functionally equivalent to:
    #
    # ~~~
    # { source: :ns__job1,
    #    destination: :ns__job2,
    #    lookup: %i[ns__job4 ns__job5]
    # }
    # ~~~
    #
    # #### Multiple sources
    #
    # All rows of all sources will be read in, transformed, and written to the
    #   destination.
    #
    # Writing CSV output will fail if all rows do not have the same fields. The
    #   Kiba::Extend::Transforms::Clean::EnsureConsistentFields transform
    #   can be added to the end of multi-source jobs to prevent this error.
    #
    # #### More flexible lookup file definition
    #
    # Lookups defined as shown above depend upon a `:lookup_on` field being
    #   configured for the job in the registry.
    #
    # What do you do if you need to use the same job (e.g.
    #   `:names__final`) as a lookup in different jobs, but need to
    #   lookup from that data on :id field in one job, and :type in
    #   another? If you have registered `:names__final` with
    #   `:lookup_on` = `:id` in your registry, you can do the
    #   following in the files argument setting up the job that needs
    #   to look up on type:
    #
    # `lookup: {jobkey: :names__final, lookup_on: :type}`
    #
    # What if you need to look up in `:names__final` by :id and :type within the
    #   same job?
    #
    # ~~~
    # lookup: [
    #   :names__final,
    #   {jobkey: :names__final, lookup_on: :type, name: :names_by_type}
    # ]
    # ~~~
    #
    # In the transforms for this job...
    #
    # ~~~
    # transform Merge::MultiRowLookup, lookup: names__final
    # ~~~
    #
    # ...will look up on :id, and...
    #
    # ~~~
    # transform Merge::MultiRowLookup, lookup: names_by_type
    # ~~~
    #
    # ...will look up on :type.
    #
    # ### `transformer` argument
    #
    # The value of `transformer` must consist of (or, more usually,
    #   must return) one or more `Kiba.job_segment` blocks defining
    #   transformation logic.
    #
    # In a given job definition module this usually looks like:
    #
    # ~~~
    # def job
    #   Kiba::Extend::Jobs::Job.new(
    #     files: { ...imagine stuff here... },
    #     transformer: xforms
    #   )
    # end
    #
    # def xforms
    #   Kiba.job_segment do
    #     transform Delete::Fields, fields: :itemtype
    #   end
    # end
    # ~~~
    #
    # However, you may give an array to `transformer`. The resulting
    #   job_segments will be included in the Job in the order you list them.
    #   This allows for powerful reuse of common transformation sequences
    #   within a project.
    #
    # ## Some technical detail partially explaining how Kiba itself creates jobs
    #
    # Running `Kiba.parse` to define a job generates a
    #   {https://github.com/thbar/kiba/blob/master/lib/kiba/control.rb
    #   Kiba::Control}
    #   object, which is a wrapper bundling together: pre_processes, config,
    #   sources, transforms, destinations, and
    #   post_processes.
    #
    # As described
    #   {https://github.com/thbar/kiba/wiki/Implementing-pre-and-post-processors
    #   here}, pre_ and post_processors get called once per ETL run---either
    #   before or after the ETL starts working through the source rows
    #
    # This Kiba::Control object created by Kiba.parse is generated with a
    #   particular Kiba::Context, and once created, you cannot get access to or
    #   manipulate variables or configuration that the entire job needs to know
    #   about.
    #
    # Kiba::Extend::Jobs adds the ability to set up reusable
    #   initial_transformers and final_transformers that go into the
    #   Kiba::Control object. Basically, job templates where just the
    #   meat of the transformations change.
    #
    # @since 2.2.0
    module Jobs
    end

    Kiba::Extend::Jobs.extend(Kiba::Extend::Jobs::Parser)
  end
end
