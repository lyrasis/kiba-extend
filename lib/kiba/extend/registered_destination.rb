require_relative 'registered_file'

module Kiba
  module Extend
    # Value object representing a destination file registered in a {Kiba::Extend::FileRegistry}
    class RegisteredDestination < RegisteredFile

      # Arguments for calling Kiba Destination class
      def args
        {filename: @data[:path], options: file_options}
      end

      # Description of file
      #
      # Used in post-processing STDOUT
      def description
        return '' unless @data.key?(:desc)
        
        @data[:desc]
      end

      # Info hash for file
      #
      # @deprecated Use {#description} and {#key} instead
      def info
        {filekey: @key, desc: description}
      end
      
      # Kiba Destination class
      def klass
        return Kiba::Extend.destination unless @data.key?(:dest_class)

        @data[:dest_class]
      end

      private

      def file_options
        return Kiba::Extend.csvopts unless @data.key?(:dest_opt)

        @data[:dest_opt]
      end
    end
  end
end
