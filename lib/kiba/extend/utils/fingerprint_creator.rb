# frozen_string_literal: true

require 'base64'

module Kiba
  module Extend
    module Utils
      # Callable service to generate a fingerprint value from the given fields
      class FingerprintCreator
        include Kiba::Extend::Transforms::Helpers

        def initialize(fields:, delim:)
          @fields = fields
          @delim = delim
        end

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
