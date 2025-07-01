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
          list = args.empty? ? Kiba::Extend.registry.entries : args.flatten
          list.each { |entry| puts entry.summary }
        end
      end
    end
  end
end
