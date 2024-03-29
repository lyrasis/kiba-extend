# frozen_string_literal: true

require_relative "registered_file"
require_relative "requirable_file"

module Kiba
  module Extend
    module Registry
      class CannotBeUsedAsSourceError < TypeError
        include Kiba::Extend::ErrMod
        attr_reader :entry
        def initialize(dest_class)
          super("The result of a registry entry with a #{dest_class} "\
                "dest_class cannot be used as source file in a job")
        end
      end

      # Value object representing a {Kiba::Extend::Registry::RegistryEntry}
      #   being used as a job source
      class RegisteredSource < RegisteredFile
        include RequirableFile

        # Arguments for calling Kiba Source class
        # @return [Hash]
        def args
          {src_class.path_key => path}.merge(src_opts)
        end

        def klass
          src_class
        end

        private

        def src_opts
          if src_opt && src_class.options_key
            {src_class.options_key => src_opt}
          elsif src_opt
            src_opt
          else
            src_class.labeled_options
          end
        end
      end
    end
  end
end
