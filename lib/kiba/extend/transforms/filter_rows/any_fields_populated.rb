# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module FilterRows
        # @since 2.9.0
        #
        # Keep or reject rows based on whether any of the given fields is populated. Blank strings and nils count as
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
        # transform FilterRows::AnyFieldsPopulated, action: :keep, fields: %i[a b]
        # ```
        #
        # Resulting data:
        #
        # ```
        # {a: 'a', b: 'b', c: 'c' },
        # {a: 'a', b: 'b', c: '' },
        # {a: '', b: 'b', c: 'c' }
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform FilterRows::AnyFieldsPopulated, action: :keep, fields: :all
        # ```
        #
        # Resulting data:
        #
        # ```
        # {a: 'a', b: 'b', c: 'c' },
        # {a: 'a', b: 'b', c: '' },
        # {a: '', b: nil, c: 'c' },
        # {a: '', b: 'b', c: 'c' }
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform FilterRows::AnyFieldsPopulated, action: :reject, fields: %i[a b]
        # ```
        #
        # Resulting data:
        #
        # ```
        # {a: '', b: nil, c: 'c' },
        # {a: '', b: nil, c: nil }
        # ```
        class AnyFieldsPopulated
          include Allable
          
          # @param action [:keep, :reject] what to do with row matching criteria
          # @param fields [Array<Symbol>, :all] to check populated status in
          def initialize(action:, fields:)
            @action = action
            @fields = [fields].flatten
          end

          # @param row [Hash{ Symbol => String }]
          def process(row)
            finalize_fields(row) unless fields_set
            
            case action
            when :keep
              return row if any_populated?(row)
            when :reject
              return row unless any_populated?(row)
            end
          end

          private

          attr_reader :action, :fields

          def any_populated?(row)
            fields.each do |field|
              val = row.fetch(field, nil)
              return true unless val.blank?
            end
            false
          end
        end
      end
    end
  end
end
