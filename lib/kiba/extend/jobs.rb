# frozen_string_literal: true

require_relative "jobs/parser"

module Kiba
  module Extend
    # Reusable, composable patterns for jobs
    #
    # rubocop:todo Layout/LineLength
    # Heretofore, I have been repeating tons of code/logic for setting up a job in migration code:
    # rubocop:enable Layout/LineLength
    #
    # - Defining sources/destinations, @srcrows, @outrows
    # - Changing CSV rows to hashes (initial transforms)
    # - Changing hashes back to CSV rows
    # - Calling postprocessing
    #
    # rubocop:todo Layout/LineLength
    # Most of this never changes, and when it does there is way too much tedious work in a given migration
    # rubocop:enable Layout/LineLength
    #   to make it consistent across all jobs.
    #
    # rubocop:todo Layout/LineLength
    # This is an attempt to dry up calling jobs and make it possible to test them via RSpec
    # rubocop:enable Layout/LineLength
    #
    # Running `Kiba.parse` to define a job generates a
    #   {https://github.com/thbar/kiba/blob/master/lib/kiba/control.rb Kiba::Control}
    # rubocop:todo Layout/LineLength
    #   object, which is a wrapper bundling together: pre_processes, config, sources, transforms, destinations, and
    # rubocop:enable Layout/LineLength
    #   post_processes.
    #
    # rubocop:todo Layout/LineLength
    # As described {https://github.com/thbar/kiba/wiki/Implementing-pre-and-post-processors here}, pre_ and post_
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    #   processors get called once per ETL run---either before or after the ETL starts working through the source
    # rubocop:enable Layout/LineLength
    #   rows
    #
    # rubocop:todo Layout/LineLength
    # This Kiba::Control object created by Kiba.parse is generated with a particular Kiba::Context, and
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    #   once created, you cannot get access to or manipulate variables or configuration that the entire
    # rubocop:enable Layout/LineLength
    #   job needs to know about.
    #
    # rubocop:todo Layout/LineLength
    # What Kiba::Extend::Jobs adds is the ability to set up reusable initial_transformers and final_transformers.
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    #   Basically, job templates where just the meat of the transformations change.
    # rubocop:enable Layout/LineLength
    #
    # rubocop:todo Layout/LineLength
    # `files` is the configuration of destination, source, and lookup files the job will use. It is a Hash, with
    # rubocop:enable Layout/LineLength
    #   the following format:
    #
    # rubocop:todo Layout/LineLength
    #  { source: [registry_key, registry_key], destination: [registry_key], lookup: [registry_key] }
    # rubocop:enable Layout/LineLength
    #
    #  { source: [registry_key, registry_key], destination: [registry_key]}
    #
    # rubocop:todo Layout/LineLength
    # `source` and `destination` must each have at least one registry key. `lookup` may be omitted, or it may
    # rubocop:enable Layout/LineLength
    #   be included with one or more registry keys
    #
    # rubocop:todo Layout/LineLength
    # `transformer` is a sequence of data transformations that could theoretically be called with interchangable
    # rubocop:enable Layout/LineLength
    #   input/output settings (i.e. `materials`).
    #
    # rubocop:todo Layout/LineLength
    # In project code, instead of defining an entire job in a `Kiba.parse` block, you will define a
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    #   `Kiba.job_segment` block containing just the transforms unique to that job.
    # rubocop:enable Layout/LineLength
    #
    # @since 2.2.0
    module Jobs
    end

    Kiba::Extend::Jobs.extend(Kiba::Extend::Jobs::Parser)
  end
end
