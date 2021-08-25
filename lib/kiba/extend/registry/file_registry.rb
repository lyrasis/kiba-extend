require 'dry-container'

require_relative 'registered_source'
require_relative 'registered_lookup'
require_relative 'registered_destination'
require_relative 'file_registry_entry'

module Kiba
  module Extend
    # Transforms a file_registry hash (like {Fwm#registry}) into an object that can return
    #   source, lookup, or destination config for that file, for passing to jobs
    class FileRegistry
      include Dry::Container::Mixin

      def created_by_class(cstr)
        entries.select{ |_, val| val.creator && val.creator.owner.to_s[cstr] }
      end
      
      def created_by_method(mstr)
        matcher = "#<Method: #{mstr}("
        entries.select{ |_, val| val.creator && val.creator.to_s[matcher] }
      end
      
      def invalid
        entries.reject{ |_, val| val.valid? }
      end

      def tagged(tag)
        entries.select{ |_, val| val.tags.any?(tag) }
      end
      
      def transform
        entries.each{ |key, val| self.decorate(key){ FileRegistryEntry.new(val) } }
        @entries = populate_entries
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

      def entries
        @entries ||= populate_entries
      end

      def populate_entries
        hash = {}
        self.each{ |entry| hash[entry[0]] = entry[1] }
        hash
      end
    end
  end
end
