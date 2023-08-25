# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      # rubocop:todo Layout/LineLength
      # Utility class used by project applications to display information about a set of
      # rubocop:enable Layout/LineLength
      #   registered files/jobs
      #
      # Puts to STDOUT
      class RegistryList
        # @param args [Array<FileRegistryEntry>]
        def initialize(*args)
          puts ""
          list = args.empty? ? Kiba::Extend.registry.entries : args.flatten
          list.each { |entry| puts entry.summary }
        end
      end
    end
  end
end
