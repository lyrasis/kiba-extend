# frozen_string_literal: true

module Kiba
  module Extend
    module Jobs
      # Mixin module for dynamic job classes. Handles dependencies, but `run`
      #   involves plain old Ruby code, not Kiba transformation logic
      #
      # ## Implementation
      #
      # There must be a `source` and `destination` method or reader/accessor
      #   attribute defined in the class.
      #
      # There must be a `job_code` method which runs the job logic. This can be
      #   a pointer/wrapper to other methods/classes/etc., but the entire logic
      #   of the job should be encapsulated in this one method call.
      #
      # Override `outrows` (and, optionally, `srcrows`) methods with
      #   appropriate logic for the output format.
      module DynamicJobable
        include DependencyHandleable
        include Reportable

        def files = setup_files({
          source: [source].flatten,
          destination: [destination].flatten
        })

        # if caller(2, 5).join(" ")["block in handle_requirements"]
        #   @dependency = true
        # end
        # extend DependencyJob if @dependency

        def run
          report_run_start # defined in Reportable
          # defined in Runnable
          %i[source lookup].each do |type|
            handle_requirements(type)
          end

          job_code

          report_run_end # defined in Reportable
        rescue => err
          puts "JOB FAILED: TRANSFORM ERROR IN: #{job_data.creator}"
          puts "#{err.class.name}: #{err.message}"
          puts "AT:"
          puts err.backtrace.first(10)
          exit
        end

        def source_path = Kiba::Extend.registry
          .resolve(source)
          &.path

        def destination_path = Kiba::Extend.registry
          .resolve(destination)
          .path

        def destination_key = destination

        def srcrows = nil

        def outrows = nil

        private

        def job_data = Kiba::Extend.registry.resolve(destination)
      end
    end
  end
end
