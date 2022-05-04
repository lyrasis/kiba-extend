# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Rename
        class Field
          def initialize(from:, to:)
            @from = from
            @to = to
          end

          # @private
          def process(row)
            unless row.key?(from)
              warn("#{Kiba::Extend.warning_label}: Field `#{from}` does not exist in row. Cannot be renamed.")
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
