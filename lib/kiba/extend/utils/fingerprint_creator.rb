# frozen_string_literal: true

require 'base64'

module Kiba
  module Extend
    module Utils
      # Callable service to generate a fingerprint value from the given fields
      # @since 2.7.1.65
      class FingerprintCreator
        include Kiba::Extend::Transforms::Helpers

        # @param fields [Array<Symbol>] fields used to build the fingerprint
        # @param delim [String] to separate field values when fields are joined for hashing
        def initialize(fields:, delim:)
          @fields = fields
          @delim = delim
        end

        # @raise [DelimInValueFingerprintError] if any of the field values in the row contain the delim. This error is
        #   caught by {Kiba::Extend::Transforms::Fingerprint::Add} and triggers raising of a more informative error
        #   to the user
        def call(row)
          values = field_values(row: row, fields: fields, discard: []).values
          check_values(values)
          
          Base64.strict_encode64(hashable_values(values).join(delim))
        end

        private

        attr_reader :fields, :delim

        def check_values(values)
          raise Kiba::Extend::Utils::DelimInValueFingerprintError if values.compact.any?{ |val| val[delim] }
        end

        def hashable_values(values)
          values.map do |val|
            case val
            when nil
              'nil'
            when ''
              'empty'
            else
              val
            end
          end
        end
      end
    end
  end
end
