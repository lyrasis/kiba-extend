# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      # Mixin module for children of {Kiba::Extend::RegisteredFile} that other jobs depend upon
      module RequirableFile
        # Exception raised if {Kiba::Extend::FileRegistry} contains no creator for file
        class NoDependencyCreatorError < StandardError
          # @param filekey [Symbol] key for file lacking creator in {Kiba::Extend::FileRegistry}
          def initialize(filekey)
            msg = "No creator method found for :#{filekey} in file registry"
            super(msg)
          end
        end

        # @return [Method] the creator method for a required dependency job
        def required
          return if File.exist?(@data.path)

          %i[missing_creator_for_non_supplied_file creator_not_a_method].each do |err|
            raise NoDependencyCreatorError, @key if @data.errors.keys.any?(err)
          end

          @data.creator
        end
      end
    end
  end
end
