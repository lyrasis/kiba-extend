# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module FilterRows
        # Keep or reject rows based on whether the given field is populated. Blank strings and nils count as
        #   not populated.
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
        # transform FilterRows::FieldPopulated, action: :keep, field: :val
        # ```
        #
        # Resulting data:
        #
        # ```
        # {val:  'N'},
        # {val:  'n'},
        # {val:  'NN'},
        # {val:  'NY'}
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform FilterRows::FieldPopulated, action: :reject, field: :val
        # ```
        #
        # Resulting data:
        #
        # ```
        # {val:  ''},
        # {val:  nil},
        # ```
        class FieldPopulated
          # @param action [:keep, :reject] what to do with row matching criteria
          # @param field [Symbol] to check populated status in
          def initialize(action:, field:)
            @action = action
            @field = field
          end

          # @private
          def process(row)
            val = row.fetch(field, nil)
            case action
            when :keep
              val.nil? || val.empty? ? nil : row
            when :reject
              val.nil? || val.empty? ? row : nil
            end
          end

          private

          attr_reader :action, :field
        end
      end
    end
  end
end