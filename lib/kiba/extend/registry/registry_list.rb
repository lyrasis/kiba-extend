# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      # Utility class used by project applications to display
      #   information about a set of registered files/jobs.
      class RegistryList
        # @param args [nil, Array<FileRegistryEntry>]
        def initialize(*args)
          @args = args
        end

        def list
          return args.flatten unless args.empty?

          Kiba::Extend.registry
            ._container
            .values
            .map(&:item)
        end

        def pretty
          puts ""
          list.each { |entry| puts entry.summary }
        end

        private

        attr_reader :args
      end
    end
  end
end
