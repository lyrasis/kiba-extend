# frozen_string_literal: true

require_relative "runner"
require_relative "parser"
require_relative "show_me_job"
require_relative "tell_me_job"
require_relative "dependency_job"

module Kiba
  module Extend
    module Jobs
      # Abstract definition of Job and job interface
      #
      # @abstract
      class BaseJob
        include Runner
        include Parser

        attr_reader :control, :context, :files, :transformer, :srcrows, :outrows

        # @param files [Hash]
        # @param transformer [Kiba::Control]
        # @param mode [:run, :setup, :info] :info mode sets up files only.
        #   :setup mode sets up files and handles requirements, including
        #   running any necessary jobs to create sources and/or lookups needed
        #   by the job. :run does all of the above and runs the job. Since 4.0.0
        def initialize(files:, transformer:, mode: :run)
          @destination_key = files[:destination].is_a?(Symbol) ?
            files[:destination] :
            files[:destination].first

          if caller(2, 5).join(" ")["block in handle_requirements"]
            @dependency = true
          end
          extend DependencyJob if @dependency

          @files = setup_files(files)

          unless mode == :info
            report_run_start # defined in Reporter
            handle_requirements # defined in Runner
            @control = Kiba::Control.new
            @context = Kiba::Context.new(control)
            @transformer = transformer
            assemble_control # defined in Runner
          end

          if mode == :run
            run
            set_row_count_instance_variables
            report_run_end # defined in Reporter
          end
        end

        def run
          Kiba.run(control)
        rescue => err
          puts "JOB FAILED: TRANSFORM ERROR IN: #{job_data.creator}"
          puts "#{err.class.name}: #{err.message}"
          puts "AT:"
          puts err.backtrace.first(10)
          exit
        end

        private

        attr_reader :destination_key

        def job_data
          @files[:destination].first.data
        end

        # Replace file key names with registered_source/lookup/destination
        #   objects dynamically
        def setup_files(files)
          tmp = {}
          files.each do |type, arr|
            meth = Kiba::Extend.registry.method("as_#{type}")
            tmp[type] = [arr].flatten
              .map { |key| prep_file(meth, key, destination_key) }
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

        def prep_file(meth, key, for_job)
          meth.call(key, for_job)
        rescue Kiba::Extend::ErrMod => err
          if err.respond_to?(:formatted)
            puts err.formatted
          else
            puts "JOB FAILED: TRANSFORM ERROR IN: #{err.calling_job}"
            err.info
          end
          exit
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

        def set_row_count_instance_variables
          %w[srcrows outrows].each do |var|
            varsym = "@#{var}".to_sym
            instance_variable_set(varsym, context.instance_variable_get(varsym))
          end
        end
      end
    end
  end
end
