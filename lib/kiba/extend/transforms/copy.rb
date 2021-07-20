# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Tranformations that copy data from one place to another
      module Copy
        ::Copy = Kiba::Extend::Transforms::Copy
        # Copy the value of a field to another field. If `to` field does not yet exist, it is created. Otherwise, it is overwritten with the copied value.
        # @todo Add `safe_copy` parameter that will prevent overwrite of existing data in `to`
        class Field
          # @param from [Symbol] Name of field to copy data from
          # @param to [Symbol] Name of field to copy data to
          def initialize(from:, to:)
            @from = from
            @to = to
          end

          # @private
          def process(row)
            row[@to] = row.fetch(@from)
            row
          end
        end
      end
    end
  end
end
