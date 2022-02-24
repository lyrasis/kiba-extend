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