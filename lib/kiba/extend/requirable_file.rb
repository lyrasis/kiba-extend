module Kiba
  module Extend
    # Mixin module for some children of {Kiba::Extend::RegisteredFile}
    module RequirableFile

      # Exception raised if {Kiba::Extend::FileRegistry} contains no creator for file
      class NoDependencyCreatorError < StandardError
        # @param filekey [Symbol] key for file lacking creator in {Kiba::Extend::FileRegistry}
        def initialize(filekey)
          msg = "No creator method found for :#{filekey} in file registry hash"
          super(msg)
        end
      end

      def required
        return if File.exist?(@data[:path])
        raise NoDependencyCreatorError, @key unless @data.key?(:creator)

        @data[:creator]
      end

      def file_options
        return Kiba::Extend.csvopts unless @data.key?(:src_opt)

        @data[:src_opt]
      end
    end
  end
end
