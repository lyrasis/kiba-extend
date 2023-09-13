# frozen_string_literal: true

require_relative "jobs/parser"

module Kiba
  module Extend
    # Reusable, composable patterns for jobs
    #
    # Heretofore, I have been repeating tons of code/logic for setting up a job
    #   in migration code:
    #
    # - Defining sources/destinations, @srcrows, @outrows
    # - Changing CSV rows to hashes (initial transforms)
    # - Changing hashes back to CSV rows
    # - Calling postprocessing
    #
    # Most of this never changes, and when it does there is way too much tedious
    #   work in a given migration to make it consistent across all jobs.
    #
    # This is an attempt to dry up calling jobs and make it possible to test
    #   them via RSpec
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
    # What Kiba::Extend::Jobs adds is the ability to set up reusable
    #   initial_transformers and final_transformers. Basically, job templates
    #   where just the meat of the transformations change.
    #
    # `files` is the configuration of destination, source, and lookup files the
    #   job will use. It is a Hash, with the following format:
    #
    #  ```
    # { source: [registry_key, registry_key],
    #    destination: [registry_key],
    #    lookup: [registry_key]
    # }
    # ~~~
    #
    # OR
    #
    # ~~~
    #  { source: [registry_key, registry_key],
    #    destination: [registry_key]
    #  }
    # ~~~
    #
    # `source` and `destination` must each have at least one registry key.
    #   `lookup` may be omitted, or it may be included with one or more registry
    #   keys
    #
    # `transformer` is a sequence of data transformations that could
    #   theoretically be called with interchangable input/output settings
    #   (i.e. `materials`).
    #
    # In project code, instead of defining an entire job in a `Kiba.parse`
    #   block, you will define a `Kiba.job_segment` block containing just the
    #   transforms unique to that job.
    #
    # @since 2.2.0
    module Jobs
    end

    Kiba::Extend::Jobs.extend(Kiba::Extend::Jobs::Parser)
  end
end
