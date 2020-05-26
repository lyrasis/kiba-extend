module Kiba
  module Extend
    module Transforms
      module Copy
        ::Copy = Kiba::Extend::Transforms::Copy
        class Field
          def initialize(from:, to:)
            @from = from
            @to = to
          end

          def process(row)
            row[@to] = row.fetch(@from)
            row
          end
        end
      end
    end
  end
end
