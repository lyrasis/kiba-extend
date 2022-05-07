# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Rename
        class Field
          include SingleWarnable

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
