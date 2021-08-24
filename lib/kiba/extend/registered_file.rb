module Kiba
  module Extend
    # Abstract base class defining interface for destination files, lookup files, and source files
    #   returned by {Kiba::Extend::FileRegistry}
    class RegisteredFile
      # Exception raised if file key is not in {Kiba::Extend::FileRegistry} data
      class FileNotRegisteredError < StandardError
        # @param filekey [Symbol] key not found in {Kiba::Extend::FileRegistry}
        def initialize(filekey)
          msg = ":#{filekey} not found as key in file registry hash"
          super(msg)
        end
      end

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
      attr_reader :key

      # @param key [Symbol] the {Kiba::Extend::FileRegistry} lookup key
      # @param data [Hash] the hash of data for the file from {Kiba::Extend::FileRegistry}
      def initialize(key:, data:)
        raise FileNotRegisteredError, key unless data
        raise NoFilePathError, key unless data.key?(:path)

        @key, @data = key, data
      end
    end
  end
end