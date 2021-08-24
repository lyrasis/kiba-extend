require_relative 'registered_source'
require_relative 'registered_lookup'
require_relative 'registered_destination'

module Kiba
  module Extend
    # Transforms a file_registry hash (like {Fwm#registry}) into an object that can return
    #   source, lookup, or destination config for that file, for passing to jobs
    class FileRegistry      
      def initialize(registry_hash)
        @reghash = registry_hash
      end

      def as_destination(filekey)
        Kiba::Extend::RegisteredDestination.new(key: built_key(filekey), data: lookup(filekey))
      end

      def as_lookup(filekey)
        Kiba::Extend::RegisteredLookup.new(key: built_key(filekey), data: lookup(filekey))
      end
      
      def as_source(filekey)
        Kiba::Extend::RegisteredSource.new(key: built_key(filekey), data: lookup(filekey))
      end

      private

      def add_require(result, file)
        return result if File.exist?(file[:path])

        result[:require] = { module: file[:creator_module], method: file[:creator_method] }
        result
      end

      def built_key(filekey)
        filekey.map(&:to_s).join('/').to_sym
      end

      def lookup(filekey)
        @reghash.dig(*filekey)
      end
    end
  end
end
