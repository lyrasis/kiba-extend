# frozen_string_literal: true

require_relative 'base_job'

module Kiba
  module Extend
    module Jobs

      # Job with one source, one destination, and zero-to-n lookups
      class TestingJob < BaseJob
        private

        def setup_files(files)
          tmp = {}
          files.each do |type, val|
            if type == :source
              tmp[type] = source_entry(val)
            elsif type == :destination
              tmp[type] = destination_entry(val)
            end
            
          end
          tmp
        end

      Entry = Struct.new(:klass, :args)

      def source_entry(input)
        Entry.new(Kiba::Common::Sources::Enumerable, input)
      end

      def destination_entry(accumulator)
        Entry.new(Kiba::Common::Destinations::Lambda, {on_write: ->(r) { accumulator << r }})
      end

      def initial_transforms
        nil
      end

      def final_transforms
        nil
        end

      def pre_process
        nil
      end

        def config
          Kiba.parse do
          end.config
        end

        def post_process
          nil
        end

        def handle_requirements
          # no requirements
        end
        
        def report_run_start
          # no reporting
        end

        def report_run_end
          # no reporting
        end

        def file_config(config)
          [{klass: config.klass, args: [config.args]}]
        end

        def sources
          file_config(@files[:source])
        end

        def destinations
          file_config(@files[:destination])
        end
      end
    end
  end
end
