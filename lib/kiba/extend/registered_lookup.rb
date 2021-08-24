require_relative 'registered_file'
require_relative 'requirable_file'

module Kiba
  module Extend
    # Value object representing a destination file registered in a {Kiba::Extend::FileRegistry}
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

      def initialize(key:, data:)
        super
        raise NoLookupKeyError, @key unless @data.key?(:key)
      end
      
      # Arguments for calling {Kiba::Extend::Lookup} with this file
      def args
        {file: @data[:path], csvopt: file_options, keycolumn: @data[:key]}
      end

      # Kiba Destination class
      def klass
        return Kiba::Extend.destination unless @data.key?(:dest_class)

        @data[:dest_class]
      end

      private

      def file_options
        return Kiba::Extend.csvopts unless @data.key?(:src_opt)

        @data[:src_opt]
      end
    end
  end
end
