# frozen_string_literal: true

module Kiba
  module Extend
    module Jobs
      # Abstract definition of Job and job interface
      #
      # @abstract
      class BaseJob
        include DependencyHandleable
        include Runnable
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
          report_run_start # defined in Reportable

          %i[source lookup].each do |type|
            handle_requirements(type) # defined in DependencyHandleable
          end

          assemble_control # defined in Runnable
          Kiba.run(control)
          set_row_count_instance_variables
          report_run_end # defined in Reportable
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
