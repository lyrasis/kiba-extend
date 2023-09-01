# frozen_string_literal: true

# rubocop:todo Layout/LineLength

require "dry-container"

require_relative "registered_source"
require_relative "registered_lookup"
require_relative "registered_destination"
require_relative "file_registry_entry"
require_relative "registry_validator"

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

        config.namespace_separator = Kiba::Extend.registry_namespace_separator

        # Exception raised if the file key is not registered
        class KeyNotRegisteredError < NameError
          include Kiba::Extend::ErrMod

          attr_reader :key, :type
          # @param key [Symbol]
          # @param type [Symbol<:destination, :source, :lookup>]
          def initialize(key, type = nil)
            @key = key
            @type = type
            keymsg = "No file registered under the key: :#{key}"
            typemsg = type ? "#{keymsg} (as #{type})" : keymsg
            super(typemsg)
          end
        end

        # @param filekey [String, Symbol] file registry key for file to be used as destination
        # @return [Kiba::Extend::Registry::RegisteredDestination]
        def as_destination(filekey)
          RegisteredDestination.new(key: filekey, data: lookup(filekey))
        rescue KeyNotRegisteredError => err
          raise KeyNotRegisteredError.new(err.key, :destination)
        end

        # @param filekey [String, Symbol] file registry key for file to be used as a lookup source
        # @return [Kiba::Extend::Registry::RegisteredLookup]
        def as_lookup(filekey)
          RegisteredLookup.new(key: filekey, data: lookup(filekey))
        rescue KeyNotRegisteredError => err
          raise KeyNotRegisteredError.new(err.key, :lookup)
        end

        # @param filekey [String, Symbol] file registry key for file to be used as a source
        # @return [Kiba::Extend::Registry::RegisteredSource]
        def as_source(filekey)
          RegisteredSource.new(key: filekey, data: lookup(filekey))
        rescue KeyNotRegisteredError => err
          raise KeyNotRegisteredError.new(err.key, :source)
        end

        # @return
        def entries
          @entries ||= populate_entries
        end

        # Convenience method combining the steps of transforming initial registry entry hashes
        #   into FileRegistryEntry objects, and then making the registry immutable for the
        #   rest of the application's run. `:freeze` is from dry-container.
        def finalize
          transform
          freeze
        end

        # Transforms registered file hashes into Kiba::Extend::Registry::FileRegistryEntry objects
        def transform
          each { |key, val| decorate(key) { FileRegistryEntry.new(val) } }
          @entries = populate_entries
          each { |key, val| val.set_key(key) }
          verify_paths
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
        rescue Dry::Container::KeyError
          fail KeyNotRegisteredError, key
        end

        def make_missing_directories
          @entries.select(&:valid?).map(&:dir).uniq.each do |dir|
            dir.mkdir unless dir.exist?
          end
        end

        def populate_entries
          arr = []
          each { |entry| arr << entry[1] }
          arr
        end

        def verify_paths
          verify_supplied_files_exist
          make_missing_directories
        end

        def verify_supplied_files_exist
          @entries.select do |entry|
            entry.supplied
          end.map(&:path).uniq.each do |file|
            next if file.exist?

            puts %(#{Kiba::Extend.warning_label}: Missing supplied file: #{file})
          end
        end

        def validator
          @validator ||= RegistryValidator.new
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
