# frozen_string_literal: true

require "base64"

module Kiba
  module Extend
    module Utils
      # Callable service to generate a fingerprint value from the given fields
      # @since 2.7.1.65
      class FingerprintCreator
        # @param fields [Array<Symbol>] fields used to build the fingerprint
        # rubocop:todo Layout/LineLength
        # @param delim [String] to separate field values when fields are joined for hashing
        # rubocop:enable Layout/LineLength
        def initialize(fields:, delim:)
          @fields = [fields].flatten
          @delim = delim
          @value_getter = Transforms::Helpers::FieldValueGetter.new(
            fields: fields, delim: delim, discard: []
          )
        end

        # rubocop:todo Layout/LineLength
        # @raise [DelimInValueFingerprintError] if any of the field values in the row contain the delim. This error is
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   caught by {Kiba::Extend::Transforms::Fingerprint::Add} and triggers raising of a more informative error
        # rubocop:enable Layout/LineLength
        #   to the user
        def call(row)
          values = value_getter.call(row).values
          check_values(values)

          Base64.strict_encode64(hashable_values(values).join(delim))
        end

        private

        attr_reader :fields, :delim, :value_getter

        def check_values(values)
          # rubocop:todo Layout/LineLength
          raise Kiba::Extend::Utils::DelimInValueFingerprintError if values.compact.any? do |val|
                                                                       # rubocop:enable Layout/LineLength
                                                                       # rubocop:todo Layout/LineLength
                                                                       val[delim]
                                                                       # rubocop:enable Layout/LineLength
                                                                     end
        end

        def hashable_values(values)
          values.map do |val|
            case val
            when nil
              "nil"
            when ""
              "empty"
            else
              val
            end
          end
        end
      end
    end
  end
end
