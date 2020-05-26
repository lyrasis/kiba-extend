module Kiba
  module Extend
    module Transforms
      module CombineValues
        ::CombineValues = Kiba::Extend::Transforms::CombineValues
        class FromFieldsWithDelimiter
          def initialize(sources:, target:, sep:, delete_sources: true)
            @sources = sources
            @target = target
            @sep = sep
            @del = delete_sources
          end

          def process(row)
            val = @sources.map{ |src| row.fetch(src) }.compact.join(@sep)
            val.empty? ? row[@target] = nil : row[@target] = val
            @sources.each{ |src| row.delete(src) } if @del
            row
          end
        end
      end
    end
  end
end
