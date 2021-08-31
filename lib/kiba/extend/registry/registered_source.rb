# frozen_string_literal: true

require_relative 'registered_file'
require_relative 'requirable_file'

module Kiba
  module Extend
    module Registry
      # Value object representing a file registered in a {Kiba::Extend::FileRegistry} that is being
      #   called into another job as a source table
      class RegisteredSource < RegisteredFile
        include RequirableFile

        # Arguments for calling Kiba Source class
        # @return [Hash]
        def args
          opts = @data.src_opt ? { options_label(klass) => @data.src_opt } : labeled_options(klass)
          [{ filename: path }.merge(opts)]
        end

        # Kiba Source class to call
        def klass
          @data.src_class
        end
      end
    end
  end
end
