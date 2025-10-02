# frozen_string_literal: true

require_relative "registered_file"
require_relative "requirable_file"

module Kiba
  module Extend
    module Registry
      # Value object representing a file registered in a
      #   {Kiba::Extend::FileRegistry} that is being called into
      #   another job as a lookup table
      #
      # Assumes this file will be used to build a {Kiba::Extend::Lookup}
      class RegisteredLookup < RegisteredFile
        include RequirableFile

        # @param key [Symbol, Hash] file key from {FileRegistry} data
        #   hash. Alternately, a Hash containing jobkey: {full jobkey
        #   symbol}, and additional key-value pairs may be passed.
        # @param data [Hash] file data from {FileRegistry}
        # @param for_job [Symbol] registry entry job key of the job for which
        #   this registered file is being prepared
        def initialize(key:, data:, for_job:)
          super
          if key.is_a?(Hash)
            @key = key[:jobkey]
            @lookup_on = key[:lookup_on] if key.key?(:lookup_on)
          end

          unless src_class.respond_to?(:is_lookupable?)
            fail Kiba::Extend::JobCannotBeUsedAsLookupError.new(
              key, src_class, for_job
            )
          end
          unless lookup_on
            fail Kiba::Extend::NoLookupOnError.new(key, for_job)
          end
          unless lookup_on.is_a?(Symbol)
            fail Kiba::Extend::NonSymbolLookupOnError.new(key, for_job)
          end
        end

        # Arguments for calling {Kiba::Extend::Lookup} with this file
        # @return [Hash]
        def args
          {file: path, keycolumn: lookup_on}.merge(options)
        end

        def klass
          src_class
        end

        private

        def options
          label = src_class.lookup_options_key
          return {label => src_opt} if src_opt

          {label => src_class.default_file_options}
        end
      end
    end
  end
end
