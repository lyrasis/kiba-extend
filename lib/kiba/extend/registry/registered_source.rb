# frozen_string_literal: true

require_relative 'registered_file'
require_relative 'requirable_file'

module Kiba
  module Extend
    module Registry
      class CannotBeUsedAsSourceError < Kiba::Extend::Error
        attr_reader :entry
        def initialize(entry)
          @entry = entry
          super("The result of a registry entry with a #{entry.dest_class} "\
                "dest_class cannot be used as source file in a job")
        end
      end

      # Value object representing a {Kiba::Extend::RegistryEntry} being used as
      #   a job source
      class RegisteredSource < RegisteredFile
        include RequirableFile

        # Arguments for calling Kiba Source class
        # @return [Hash]
        def args
          { filename: path }.merge(src_opts)
        end

        # Kiba Source class to call
        def klass
          @data.supplied ? @data.src_class : dest_src
        end

        private

        def dest_src
          src = dest_src_mapping(@data.dest_class)
          raise CannotBeUsedAsSourceError.new(@data) if src.nil?

          src
        end

        def src_opts
          return { options_label(klass) => @data.src_opt } if @data.src_opt

          labeled_options(klass)
        end
      end
    end
  end
end
