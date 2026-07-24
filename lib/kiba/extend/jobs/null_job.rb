# frozen_string_literal: true

module Kiba
  module Extend
    module Jobs
      # Placeholder job that reports that given name (or generic null job)
      #   was run, but does not actually try to run a real job.
      #
      # This is useful in projects with dynamically-defined or registered jobs
      #   when some dependency jobs (sources, lookups) may not return any
      #   output yet (or ever).
      # @since 7.0.0
      class NullJob < BaseJob
        # @param name [NilValue] - DEPRECATED - do not use
        # @param files [Hash] as passed to a normal Job.
        def initialize(name = nil, files:)
          super(files: files, transformer: nil)
        end

        def run
          puts "#{destination_key} was run as Kiba::Extend::Jobs::NullJob"
        end

        def outrows = 0

        private

        attr_reader :name
      end
    end
  end
end
