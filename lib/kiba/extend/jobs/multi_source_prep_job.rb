# frozen_string_literal: true

require_relative 'job'

module Kiba
  module Extend
    module Jobs
      # After this job has completed processing, it adds the list of resulting fields to the
      #   given helper
      # @note This job should only be run using Kiba::Extend::Destinations::CSV destination
      # @since 2.7.0
      # @see Kiba::Extend::Utils::MultiSourceNormalizer Usage example
      class MultiSourcePrepJob < Job
        class WrongDestinationTypeError < StandardError
          def initialize(msg='Destination must be a Kiba::Extend::Destinations::CSV')
            super
          end
        end

        class WrongHelperTypeError < StandardError
          def initialize(msg='Helper must be a Kiba::Extend::Utils::MultiSourceNormalizer')
            super
          end
        end

        # @param files [Hash]
        # @param transformer [Proc]
        # @param helper [Kiba::Extend::Utils::MultiSourceNormalizer]
        # @raise WrongDestinationTypeError unless destination source is instance of {Kiba::Extend::Destinations::CSV}
        # @raise WrongHelperTypeError unless helper is instance of {Kiba::Extend::Utils::MultiSourceNormalizer}
        def initialize(files:, transformer:, helper:)
          raise WrongDestinationTypeError unless valid_destination?(files)
          raise WrongHelperTypeError unless helper.is_a?(Kiba::Extend::Utils::MultiSourceNormalizer)
         
          @helperobj = helper
          super(files: files, transformer: transformer)
        end
        
        private

        def pre_process
          context.instance_variable_set(:@helper, @helperobj)
          Kiba.job_segment do
            pre_process do
              @srcrows = 0
              @outrows = 0
            end
          end
        end
        
        def post_process
          Kiba.job_segment do
            post_process do
              dest_def = @control.destinations.first
              dest = Kiba::StreamingRunner.to_instance(dest_def[:klass], dest_def[:args], nil, false, true)
              helper = instance_variable_get(:@helper)
              helper.record_fields(dest.fields)
            end
          end
        end

        def valid_destination?(files)
          dest = files[:destination]
          return false unless dest.is_a?(Symbol)

          dest_entry = Kiba::Extend.registry.as_destination(dest)
          dest_entry.klass == Kiba::Extend::Destinations::CSV
        end
      end
    end
  end
end
