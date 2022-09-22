# frozen_string_literal: true

require_relative 'runner'
require_relative 'parser'
require_relative 'show_me_job'
require_relative 'tell_me_job'
require_relative 'dependency_job'

module Kiba
  module Extend
    module Jobs
      # Abstract definition of Job and job interface
      #
      # @abstract
      # @return [Kiba::Control]
      class BaseJob
        include Runner
        include Parser

        attr_reader :control, :context, :files, :transformer, :srcrows, :outrows

        # @param files [Hash]
        # @param transformer [Kiba::Control]
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
          set_row_count_instance_variables
        end

        def run
          Kiba.run(control)
        rescue Kiba::Extend::Error => err
          puts "JOB FAILED: TRANSFORM ERROR IN: #{job_data.creator.to_s}"
          puts "#{err.class.name}: #{err.message}"
          exit
        end

        private

        def job_data
          @files[:destination].first.data
        end

        # Replace file key names with registered_source/lookup/destination objects dynamically
        def setup_files(files)
          tmp = {}
          files.each do |type, arr|
            meth = Kiba::Extend.registry.method("as_#{type}")
            tmp[type] = [arr].flatten.map { |key| prep_file(meth, key) }
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

        def prep_file(meth, key)
          meth.call(key)
        rescue Kiba::Extend::Registry::FileRegistry::KeyNotRegisteredError => err
          puts "JOB FAILED: TRANSFORM ERROR IN: #{err.calling_job}"
          puts "#{err.class.name}: #{err.message}"
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
