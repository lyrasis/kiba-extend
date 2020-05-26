module Kiba
  module Extend
    module Transforms
      module Rename
        ::Rename = Kiba::Extend::Transforms::Rename
        class Field
          def initialize(from:, to:)
            @from = from
            @to = to
          end

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
