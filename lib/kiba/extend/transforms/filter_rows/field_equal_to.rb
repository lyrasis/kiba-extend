# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module FilterRows
        # Keep or reject rows where the value of the specified field exactly matches the given value
        #
        # ## Examples
        #
        # Source data:
        #
        # ```
        # {val:  'N'},
        # {val:  'n'},
        # {val:  'NN'},
        # {val:  'NY'},
        # {val:  ''},
        # {val:  nil}
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform FilterRows::FieldEqualTo, action: :keep, field: :val, value: 'N'
        # ```
        #
        # Resulting data:
        #
        # ```
        # {val:  'N'}
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform FilterRows::FieldEqualTo, action: :reject, field: :val, value: 'N'
        # ```
        #
        # Resulting data:
        #
        # ```
        # {val:  'n'},
        # {val:  'NN'},
        # {val:  'NY'},
        # {val:  ''},
        # {val:  nil}
        # ```
        class FieldEqualTo
          # @param action [:keep, :reject] what to do with row matching criteria
          # @param field [Symbol] to match value in
          # @param value [String] value to match
          def initialize(action:, field:, value:)
            @column = field
            @value = value
            @action = action
          end

          # @param row [Hash{ Symbol => String }]
          def process(row)
            case action
            when :keep
              row.fetch(column, nil) == value ? row : nil
            when :reject
              row.fetch(column, nil) == value ? nil : row
            end
          end

          private

          attr_reader :column, :value, :action
        end
      end
    end
  end
end
