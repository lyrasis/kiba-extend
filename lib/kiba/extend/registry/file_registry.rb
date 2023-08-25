# frozen_string_literal: true

require "dry-container"

require_relative "registered_source"
require_relative "registered_lookup"
require_relative "registered_destination"
require_relative "file_registry_entry"
require_relative "registry_validator"

module Kiba
  module Extend
    module Registry
      # rubocop:todo Layout/LineLength
      # Transforms a file_registry hash into an object that can return source, lookup, or destination
      # rubocop:enable Layout/LineLength
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

        # rubocop:todo Layout/LineLength
        # @param filekey [String, Symbol] file registry key for file to be used as destination
        # rubocop:enable Layout/LineLength
        # @return [Kiba::Extend::Registry::RegisteredDestination]
        def as_destination(filekey)
          RegisteredDestination.new(key: filekey, data: lookup(filekey))
        rescue KeyNotRegisteredError => err
          raise KeyNotRegisteredError.new(err.key, :destination)
        end

        # rubocop:todo Layout/LineLength
        # @param filekey [String, Symbol] file registry key for file to be used as a lookup source
        # rubocop:enable Layout/LineLength
        # @return [Kiba::Extend::Registry::RegisteredLookup]
        def as_lookup(filekey)
          RegisteredLookup.new(key: filekey, data: lookup(filekey))
        rescue KeyNotRegisteredError => err
          raise KeyNotRegisteredError.new(err.key, :lookup)
        end

        # rubocop:todo Layout/LineLength
        # @param filekey [String, Symbol] file registry key for file to be used as a source
        # rubocop:enable Layout/LineLength
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

        # rubocop:todo Layout/LineLength
        # Convenience method combining the steps of transforming initial registry entry hashes
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   into FileRegistryEntry objects, and then making the registry immutable for the
        # rubocop:enable Layout/LineLength
        #   rest of the application's run. `:freeze` is from dry-container.
        def finalize
          transform
          freeze
        end

        # rubocop:todo Layout/LineLength
        # Transforms registered file hashes into Kiba::Extend::Registry::FileRegistryEntry objects
        # rubocop:enable Layout/LineLength
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
          @entries.select(&:valid?).map(&:dir).uniq.each { |dir|
            dir.mkdir unless dir.exist?
          }
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
          @entries.select { |entry|
            entry.supplied
          }.map(&:path).uniq.each do |file|
            next if file.exist?

            # rubocop:todo Layout/LineLength
            puts %(#{Kiba::Extend.warning_label}: Missing supplied file: #{file})
            # rubocop:enable Layout/LineLength
          end
        end

        def validator
          @validator ||= RegistryValidator.new
        end
      end
    end
  end
end
