# frozen_string_literal: true

require 'dry-container'

require_relative 'registered_source'
require_relative 'registered_lookup'
require_relative 'registered_destination'
require_relative 'file_registry_entry'
require_relative 'registry_validator'

module Kiba
  module Extend
    module Registry
      # Transforms a file_registry hash into an object that can return source, lookup, or destination
      #   config for that file, for passing to jobs
      #
      # An example of a file registry setup in a project can be found at:
      #   https://github.com/lyrasis/fwm-cspace-migration/blob/main/lib/fwm/registry_data.rb
      class FileRegistry
        include Dry::Container::Mixin

        config.namespace_separator = '__'

        # Exception raised if the file key is not registered
        class KeyNotRegisteredError < StandardError
          # @param filekey [Symbol]
          def initialize(filekey)
            msg = "No file registered under the key: :#{filekey}"
            super(msg)
          end
        end

        # @param filekey [String, Symbol] file registry key for file to be used as destination
        # @return [Kiba::Extend::Registry::RegisteredDestination]
        def as_destination(filekey)
          RegisteredDestination.new(key: filekey, data: lookup(filekey))
        end

        # @param filekey [String, Symbol] file registry key for file to be used as a lookup source
        # @return [Kiba::Extend::Registry::RegisteredLookup]
        def as_lookup(filekey)
          RegisteredLookup.new(key: filekey, data: lookup(filekey))
        end

        # @param filekey [String, Symbol] file registry key for file to be used as a source
        # @return [Kiba::Extend::Registry::RegisteredSource]
        def as_source(filekey)
          RegisteredSource.new(key: filekey, data: lookup(filekey))
        end

        # @return
        def entries
          @entries ||= populate_entries
        end

        def transform
          each { |key, val| decorate(key) { FileRegistryEntry.new(val) } }
          @entries = populate_entries
          each { |key, val| val.set_key(key) }
        end

        def valid?
          validator.valid?
        end

        def warnings?
          validator.warnings?
        end

        private

        def lookup(key)
          resolve(key)
        rescue Dry::Container::Error
          raise KeyNotRegisteredError, key
        end

        def populate_entries
          arr = []
          each { |entry| arr << entry[1] }
          arr
        end

        def validator
          @validator ||= RegistryValidator.new
        end
      end
    end
  end
end
