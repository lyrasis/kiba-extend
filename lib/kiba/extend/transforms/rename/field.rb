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

          # @param from [Symbol] current field name
          # @param to [Symbol] target field name
          def initialize(from:, to:)
            @from = from
            @to = to
            setup_single_warning
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            unless row.key?(from)
              # rubocop:todo Layout/LineLength
              add_single_warning("Cannot rename field: `#{from}` does not exist in row")
              # rubocop:enable Layout/LineLength
              return row
            end

            # rubocop:todo Layout/LineLength
            add_single_warning("Renaming `#{from}` to `#{to}` overwrites existing `#{to}` field data") if row.key?(to)
            # rubocop:enable Layout/LineLength

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
