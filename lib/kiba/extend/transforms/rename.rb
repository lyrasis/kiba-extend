# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transformations that change the name(s) of elements in the data
      module Rename
        ::Rename = Kiba::Extend::Transforms::Rename
        class Field
          def initialize(from:, to:)
            @from = from
            @to = to
          end

          # @private
          def process(row)
            row[@to] = row.fetch(@from)
            row.delete(@from)
            row
          end
        end
      end
    end
  end
end
