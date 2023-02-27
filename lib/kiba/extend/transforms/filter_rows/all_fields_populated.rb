# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module FilterRows
        # @since 2.9.0
        #
        # Keep or reject rows based on whether all of the given fields are populated. Blank strings and nils count as
        #   not populated.
        #
        # ## Examples
        #
        # Source data:
        #
        # ```
        # {a: 'a', b: 'b', c: 'c' },
        # {a: 'a', b: 'b', c: '' },
        # {a: '', b: nil, c: 'c' },
        # {a: '', b: 'b', c: 'c' },
        # {a: '', b: nil, c: nil },
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform FilterRows::AllFieldsPopulated, action: :keep, fields: %i[a b]
        # ```
        #
        # Resulting data:
        #
        # ```
        # {a: 'a', b: 'b', c: 'c' },
        # {a: 'a', b: 'b', c: '' },
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform FilterRows::AllFieldsPopulated, action: :keep, fields: :all
        # ```
        #
        # Resulting data:
        #
        # ```
        # {a: 'a', b: 'b', c: 'c' }
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform FilterRows::AllFieldsPopulated, action: :reject, fields: %i[a b]
        # ```
        #
        # Resulting data:
        #
        # ```
        # {a: '', b: nil, c: 'c' },
        # {a: '', b: 'b', c: 'c' },
        # {a: '', b: nil, c: nil }
        # ```
        class AllFieldsPopulated
          include ActionArgumentable
          include Allable

          # @param action [:keep, :reject] what to do with row matching criteria
          # @param fields [Array<Symbol>, :all] to check populated status in
          def initialize(action:, fields:)
            validate_action_argument(action)
            @action = action
            @fields = [fields].flatten
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            finalize_fields(row) unless fields_set

            case action
            when :keep
              return row if all_populated?(row)
            when :reject
              return row unless all_populated?(row)
            end
          end

          private

          attr_reader :action, :fields

          def all_populated?(row)
            fields.each do |field|
              val = row.fetch(field, nil)
              return false if val.blank?
            end
            true
          end
        end
      end
    end
  end
end
