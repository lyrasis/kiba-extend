# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Cspace
        class ConvertToID
          def initialize(source:, target:)
            @source = source
            @target = target
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            val = row.fetch(@source, "")
            idval = val.gsub(/\W/, "")
            row[@target] = "#{idval}#{XXhash.xxh32(idval)}"
            row
          end
        end
      end
    end
  end
end
