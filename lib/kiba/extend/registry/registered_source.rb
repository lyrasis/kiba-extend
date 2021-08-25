require_relative 'registered_file'
require_relative 'requirable_file'

module Kiba
  module Extend
    # Value object representing a file registered in a {Kiba::Extend::FileRegistry} that is being
    #   called into another job as a source table
    class RegisteredSource < RegisteredFile
      include RequirableFile
      
      # Arguments for calling Kiba Source class
      # @return [Hash]
      def args
        {filename: @data.path, options: file_options}
      end

      # Kiba Source class to call
      def klass
        @data.src_class
      end
    end
  end
end
