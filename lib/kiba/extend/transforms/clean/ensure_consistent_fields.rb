# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Clean
        # Ensures each output `Hash`/row has the same keys. This is important
        #   for writing out to {Kiba::Extend::Destinations::CSV}, which expects
        #   all rows to have the same headers
        #
        # @example
        #   # Used in pipeline as:
        #   # transform Clean::EnsureConsistentFields
        #   xform = Clean::EnsureConsistentFields.new
        #   input = [
        #     {foo: 'foo', bar: 'bar'},
        #     {baz: 'baz', boo: 'boo'}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(
        #     input, xform
        #   ).map{ |row| row }
        #   expected = [
        #     {foo: 'foo', bar: 'bar', baz: nil, boo: nil},
        #     {foo: nil, bar: nil, baz: 'baz', boo: 'boo'}
        #   ]
        #   expect(result).to eq(expected)
        class EnsureConsistentFields
          def initialize
            @keys = {}
            @rows = []
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            @keys = keys.merge(row.keys
                        .map{ |key| [key, nil] }
                        .to_h)
            @rows << row
            nil
          end

          def close
            @allfields = keys.keys

            rows.each do |row|
              yield add_fields(row)
            end
          end

          private

          attr_reader :keys, :rows, :allfields

          def add_fields(row)
            needed = allfields - row.keys
            return row if needed.empty?

            row.merge(needed.map{ |field| [field, nil] }.to_h)
          end
        end
      end
    end
  end
end
