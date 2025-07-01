# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      # Utility class used by project applications to display
      #   information about a set of registered files/jobs. Puts to
      #   STDOUT
      class RegistryList
        # @param args [nil, Array<FileRegistryEntry>]
        def initialize(*args)
          puts ""
          list(args).each { |entry| puts entry.summary }
        end

        private

        def list(args)
          return args.flatten unless args.empty?

          Kiba::Extend.registry
            ._container
            .values
            .map(&:item)
        end
      end
    end
  end
end
