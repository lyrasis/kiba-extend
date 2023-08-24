# frozen_string_literal: true

require_relative "registered_file"
require_relative "requirable_file"

module Kiba
  module Extend
    module Registry
      # Value object representing a file registered in a {Kiba::Extend::FileRegistry} that is being
      #   called into another job as a lookup table
      #
      # Assumes this file will be used to build a {Kiba::Extend::Lookup}
      class RegisteredLookup < RegisteredFile
        include RequirableFile

        class CannotBeUsedAsLookupError < TypeError
          include Kiba::Extend::ErrMod
          def initialize(klass)
            super("The result of a registry entry with a #{klass} "\
                  "dest_class cannot be used as source file in a job")
          end
        end

        # Exception raised if {Kiba::Extend::FileRegistry} contains no lookup key for file
        class NoLookupKeyError < NameError
          include Kiba::Extend::ErrMod
          # @param filekey [Symbol] key not found in {Kiba::Extend::FileRegistry}
          def initialize(filekey)
            msg = "No lookup key column found for :#{filekey} in file registry hash"
            super(msg)
          end
        end

        # Exception raised if the lookup key value for the file is not a Symbol
        class NonSymbolLookupKeyError < TypeError
          include Kiba::Extend::ErrMod
          # @param filekey [Symbol] key not found in {Kiba::Extend::FileRegistry}
          def initialize(filekey)
            msg = "Lookup key found for :#{filekey} is not a Ruby Symbol. Prepend a : to the field name to fix."
            super(msg)
          end
        end

        # @param key [Symbol] file key from {FileRegistry} data hash
        # @param data [Hash] file data from {FileRegistry}
        def initialize(key:, data:)
          super
          unless src_class.respond_to?(:is_lookupable?)
            fail CannotBeUsedAsLookupError.new(src_class)
          end
          fail NoLookupKeyError, @key unless lookup_on
          unless lookup_on.is_a?(Symbol)
            fail NonSymbolLookupKeyError, @key
          end
        end

        # Arguments for calling {Kiba::Extend::Lookup} with this file
        # @return [Hash]
        def args
          {file: path, keycolumn: lookup_on}.merge(options)
        end

        def klass
          src_class
        end

        private

        def options
          label = src_class.lookup_options_key
          return {label => src_opt} if src_opt

          {label => src_class.default_file_options}
        end
      end
    end
  end
end
