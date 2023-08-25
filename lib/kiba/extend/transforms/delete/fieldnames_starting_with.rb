# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Delete
        # Deletes field(s) whose names begin with the given prefix string
        #
        # @example
        #   # Used in pipeline as:
        #   # transform Delete::FieldnamesStartingWith,
        #   #   prefix: "fp_"
        #   xform = Delete::FieldnamesStartingWith.new(
        #     prefix: "fp_"
        #   )
        #   input = [
        #     {a: 'ant', b: 'bee', c: nil, d: 'deer', e: nil,
        #      fp: 'YmVlOzs7bmlsOzs7ZGVlcjs7O2VtcHR5',
        #      fp_b: 'bee', fp_c: nil, fp_d: 'deer', fp_e: '',
        #      changed: nil},
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {a: 'ant', b: 'bee', c: nil, d: 'deer', e: nil,
        #      fp: 'YmVlOzs7bmlsOzs7ZGVlcjs7O2VtcHR5',
        #      changed: nil},
        #   ]
        #   expect(result).to eq(expected)
        class FieldnamesStartingWith
          # @param prefix [String] if a fieldname begins with or equals this
          #   string, the field will be deleted
          def initialize(prefix:)
            @prefix = prefix
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            row.keys.each do |field|
              next unless field.to_s.start_with?(prefix)

              row.delete(field)
            end

            row
          end

          private

          attr_reader :prefix
        end
      end
    end
  end
end
