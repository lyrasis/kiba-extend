# frozen_string_literal: true

require_relative 'runner'
require_relative 'parser'
require_relative 'show_me_job'
require_relative 'tell_me_job'
require_relative 'dependency_job'

module Kiba
  module Extend
    # Reusable, composable patterns for jobs
    #
    # Heretofore, I have been repeating tons of code/logic for setting up a job in migration code:
    #
    # - Defining sources/destinations, @srcrows, @outrows
    # - Changing CSV rows to hashes (initial transforms)
    # - Changing hashes back to CSV rows
    # - Calling postprocessing
    #
    # Most of this never changes, and when it does there is way too much tedious work in a given migration
    #   to make it consistent across all jobs.
    #
    # This is an attempt to dry up calling jobs and make it possible to test them automatically with stubbed-in
    #   enumerable sources/destinations
    #
    # Running `Kiba.parse` to define a job generates a {https://github.com/thbar/kiba/blob/master/lib/kiba/control.rb Kiba::Control}
    #   object, which is a wrapper bundling together: pre_processes, config, sources, transforms, destinations, and
    #   post_processes.
    #
    # As described {https://github.com/thbar/kiba/wiki/Implementing-pre-and-post-processors here}, pre_ and post_
    #   processors get called once per ETL run---either before or after the ETL starts working through the source
    #   rows
    #
    # What Kiba::Extend::Jobs add is the ability to set up reusable initial_transformers and final_transformers.
    #   Basically, job templates where just the meat of the transformations change.
    #
    # `files` is the configuration of destination, source, and lookup files the job will use. It is a Hash, with
    #   the following format:
    #
    #  { source: [registry_key, registry_key], destination: [registry_key], lookup: [registry_key] }
    #
    #  { source: [registry_key, registry_key], destination: [registry_key]}
    #
    # `source` and `destination` must each have at least one registry key. `lookup` may be omitted, or it may
    #   be included with one or more registry keys
    #
    # `transformer` is a sequence of data transformations that could theoretically be called with interchangable
    #   input/output settings (i.e. `materials`). In practice, a `recipe` is usually closely tied to particular tables, because
    #   fields are manipulated by name. However, this should support easier automated testing of `recipes`.
    #
    # @since 2.2.0
    module Jobs
      # Abstract definition of Job and job interface
      #
      # @abstract
      # @return [Kiba::Control]
      class BaseJob
        include Runner
        include Parser

        attr_reader :control, :context, :files, :transformer

        # @param files [Hash]
        # @param transformer [Kiba::Control]
        # @param show [Boolean]
        def initialize(files:, transformer:)
          @dependency = true if caller(2, 5).join(' ')['block in handle_requirements']
          extend DependencyJob if @dependency

          @files = setup_files(files)
          report_run_start # defined in Reporter
          @control = Kiba::Control.new
          @context = Kiba::Context.new(control)
          @transformer = transformer
          handle_requirements # defined in Runner
          assemble_control # defined in Runner
          run
          report_run_end # defined in Reporter
        end

        def run
          Kiba.run(control)
        end

        private

        def job_data
          @files[:destination].first.data
        end

        # Replace file key names with registered_source/lookup/destination objects dynamically
        def setup_files(files)
          tmp = {}
          files.each do |type, arr|
            method = Kiba::Extend.registry.method("as_#{type}")
            tmp[type] = [arr].flatten.map { |key| method.call(key) }
          end
          tmp
        end

        def initial_transforms
          Kiba.job_segment do
          end
        end

        def final_transforms
          Kiba.job_segment do
          end
        end

        def pre_process
          Kiba.job_segment do
          end
        end

        def config
          Kiba.parse do
          end.config
        end

        def post_process
          Kiba.job_segment do
            post_process do
            end
          end
        end
      end
    end
  end
end
