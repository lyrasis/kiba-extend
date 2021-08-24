require_relative 'registered_file'
require_relative 'requirable_file'

module Kiba
  module Extend
    # Value object representing a file registered in a {Kiba::Extend::FileRegistry} that is being
    #   called into another job as a lookup table
    class RegisteredLookup < RegisteredFile
      include RequirableFile
      # Exception raised if {Kiba::Extend::FileRegistry} contains no lookup key for file
      class NoLookupKeyError < StandardError
        # @param filekey [Symbol] key not found in {Kiba::Extend::FileRegistry}
        def initialize(filekey)
          msg = "No lookup key found for :#{filekey} in file registry hash"
          super(msg)
        end
      end

      # @param key [Symbol] file key from {FileRegistry} data hash
      # @param data [Hash] file data from {FileRegistry}
      def initialize(key:, data:)
        super
        raise NoLookupKeyError, @key unless @data.key?(:key)
      end
      
      # Arguments for calling {Kiba::Extend::Lookup} with this file
      # @return [Hash]
      def args
        {file: @data[:path], csvopt: file_options, keycolumn: @data[:key]}
      end
    end
  end
end