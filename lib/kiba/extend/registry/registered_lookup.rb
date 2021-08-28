require_relative 'registered_file'
require_relative 'requirable_file'

module Kiba
  module Extend
    # Value object representing a file registered in a {Kiba::Extend::FileRegistry} that is being
    #   called into another job as a lookup table
    #
    # Assumes this file will be used to build a {Kiba::Extend::Lookup}
    class RegisteredLookup < RegisteredFile
      include RequirableFile
      # Exception raised if {Kiba::Extend::FileRegistry} contains no lookup key for file
      class NoLookupKeyError < StandardError
        # @param filekey [Symbol] key not found in {Kiba::Extend::FileRegistry}
        def initialize(filekey)
          msg = "No lookup key column found for :#{filekey} in file registry hash"
          super(msg)
        end
      end

      class NonSymbolLookupKeyError < StandardError
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
        raise NoLookupKeyError, @key unless @data.lookup_on
        raise NonSymbolLookupKeyError, @key unless @data.lookup_on.is_a?(Symbol)
      end
      
      # Arguments for calling {Kiba::Extend::Lookup} with this file
      # @return [Hash]
      def args
        opts = @data.src_opt ? @data.src_opt : file_options(@data.src_class)
        {file: path, csvopt: opts, keycolumn: @data.lookup_on}
      end
    end
  end
end