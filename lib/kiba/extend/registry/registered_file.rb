# frozen_string_literal: true

require_relative 'source_dest_registry'

module Kiba
  module Extend
    module Registry
      # Abstract base class defining interface for destination files, lookup files, and source files
      #   returned by {Kiba::Extend::FileRegistry}
      class RegisteredFile
        include SourceDestRegistry
        # Exception raised if no path is given in {FileRegistry} hash
        class NoFilePathError < StandardError
          # @param filekey [Symbol] key for which a file path was not found in {Kiba::Extend::FileRegistry}
          def initialize(filekey)
            msg = "No file path for :#{filekey} is recorded in file registry hash"
            super(msg)
          end
        end

        # @!attribute [r] key
        #   @return [Symbol] The file's key in {FileRegistry} hash
        attr_reader :key, :data, :path, :dest_class, :src_class, :src_opt,
          :supplied, :lookup_on

        # @param key [Symbol] the {Kiba::Extend::FileRegistry} lookup key
        # @param data [Hash] the hash of data for the file from {Kiba::Extend::FileRegistry}
        def initialize(key:, data:)
          raise FileNotRegisteredError, key unless data
          raise NoFilePathError, key if data.errors.keys.any?(:missing_path)

          @key = key
          @data = data
          @path = data.path.to_s
          @dest_class = data.dest_class
          @src_opt = data.src_opt
          @supplied = data.supplied
          @lookup_on = data.lookup_on
        end

        def src_class
          supplied ? data.src_class : dest_src
        end

        private

        # returns equivalent source class for given destination class
        def dest_src
          src = dest_class.as_source_class
          raise CannotBeUsedAsSourceError.new(dest_class) if src.nil?

          src
        end
      end
    end
  end
end
