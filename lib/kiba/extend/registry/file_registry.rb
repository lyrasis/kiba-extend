require 'dry-container'

require_relative 'registered_source'
require_relative 'registered_lookup'
require_relative 'registered_destination'
require_relative 'custom_registry'

module Kiba
  module Extend
    # Transforms a file_registry hash (like {Fwm#registry}) into an object that can return
    #   source, lookup, or destination config for that file, for passing to jobs
    class FileRegistry
      extend Dry::Container::Mixin

      config.registry = CustomRegistry
      
      def as_destination(filekey)
        Kiba::Extend::RegisteredDestination.new(key: built_key(filekey), data: lookup(filekey))
      end

      def as_lookup(filekey)
        Kiba::Extend::RegisteredLookup.new(key: built_key(filekey), data: lookup(filekey))
      end
      
      def as_source(filekey)
        Kiba::Extend::RegisteredSource.new(key: built_key(filekey), data: lookup(filekey))
      end
    end
  end
end
