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
          Base64.strict_encode64(values(row).join(delim))
        end

        private

        attr_reader :fields, :delim

        def raw_values(row)
          field_values(row: row, fields: fields, discard: []).values
        end

        def values(row)
          raw_values(row).map do |val|
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
