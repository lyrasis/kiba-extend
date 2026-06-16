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

        attr_reader :files, :transformer, :srcrows, :outrows

        # @param files [Hash]
        # @param transformer [Kiba::Control]
        def initialize(files:, transformer:)
          @destination_key = files[:destination].is_a?(Symbol) ?
            files[:destination] :
            files[:destination].first

          if caller(2, 5).join(" ")["block in handle_requirements"]
            @dependency = true
          end
          extend DependencyJob if @dependency

          @files = setup_files(files.transform_values { |v| [v].flatten })
          @transformer = transformer
        end

        def control = @control ||= Kiba::Control.new

        def context = @context ||= Kiba::Context.new(control)

        def run
          report_run_start # defined in Reporter
          # defined in Runner
          %i[source lookup].each do |type|
            handle_requirements(type)
          end
          assemble_control # defined in Runner
          Kiba.run(control)
          set_row_count_instance_variables
          report_run_end # defined in Reporter
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
          files.map { |type, arr| [type, setup_files_for(type, arr)] }
            .to_h
        end

        def setup_files_for(type, arr)
          arr.map do |key|
            prep_file(
              Kiba::Extend.registry.method(:"as_#{type}"), key, destination_key
            )
          end
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
            varsym = :"@#{var}"
            instance_variable_set(varsym, context.instance_variable_get(varsym))
          end
        end
      end
    end
  end
end
