require 'dry-container'

require_relative 'registered_source'
require_relative 'registered_lookup'
require_relative 'registered_destination'
require_relative 'file_registry_entry'
require_relative 'registry_validator'

module Kiba
  module Extend
    # Transforms a file_registry hash (like {Fwm#registry}) into an object that can return
    #   source, lookup, or destination config for that file, for passing to jobs
    class FileRegistry
      include Dry::Container::Mixin

      self.config.namespace_separator = '__'
      
      # Exception raised if the file key is not registered
      class KeyNotRegisteredError < StandardError
        # @param filekey [Symbol]
        def initialize(filekey)
          msg = "No file registered under the key: :#{filekey}"
          super(msg)
        end
      end

      def as_destination(filekey)
        Kiba::Extend::RegisteredDestination.new(key: filekey, data: lookup(filekey))
      end

      def as_lookup(filekey)
        Kiba::Extend::RegisteredLookup.new(key: filekey, data: lookup(filekey))
      end
      
      def as_source(filekey)
        Kiba::Extend::RegisteredSource.new(key: filekey, data: lookup(filekey))
      end

      def entries
        @entries ||= populate_entries
      end
      
      def transform
        self.each { |key, val| self.decorate(key){ FileRegistryEntry.new(val) } }
        @entries = populate_entries
        self.each{ |key, val| val.set_key(key) }
      end

      def valid?
        validator.valid?
      end

      def warnings?
        validator.warnings?
      end
      
      private

      def lookup(key)
        self.resolve(key)
      rescue Dry::Container::Error
        raise KeyNotRegisteredError, key
      end
      
      def populate_entries
        arr = []
        self.each{ |entry| arr << entry[1] }
        arr
      end

      def validator
        @validator ||= RegistryValidator.new
      end
    end
  end
end
