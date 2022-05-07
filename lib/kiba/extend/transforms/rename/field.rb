# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Rename
        # Renames one field
        # # Examples
        #
        # Input rows:
        #
        # ```
        # {name: 'Weddy', sex: 'm'},
        # {name: 'Kernel', sex: 'f'}
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Rename::Field, from: :sex, to: :gender
        # ```
        #
        # Results in:
        #
        # ```
        # {name: 'Weddy', gender: 'm'},
        # {name: 'Kernel', gender: 'f'}
        # ```
        class Field
          include SingleWarnable

          # @param from Symbol current field name
          # @param to Symbol target field name
          def initialize(from:, to:)
            @from = from
            @to = to
            setup_single_warning
          end

          # @private
          def process(row)
            unless row.key?(from)
              add_single_warning("Cannot rename field: `#{from}` does not exist in row")
              return row
            end

            add_single_warning("Renaming `#{from}` to `#{to}` overwrites existing `#{to}` field data") if row.key?(to)
            
            row[to] = row.fetch(from)
            row.delete(from)
            row
          end

          private

          attr_reader :from, :to
        end
      end
    end
  end
end
