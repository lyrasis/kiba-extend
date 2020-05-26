module Kiba
  module Extend
    module Transforms
      module Replace
        ::Replace = Kiba::Extend::Transforms::Replace
        class FieldValueWithStaticMapping
          def initialize(source:, target:, mapping:, delete_sources: true)
            @source = source
            @target = target
            @mapping = mapping
            @mapping[nil] = nil unless @mapping.has_key?(nil)
            @del = delete_sources
          end

          def process(row)
            origval = row.fetch(@source)
            if @mapping.has_key?(origval)
              row[@target] = @mapping[origval]
            else
              row[@target] = origval
              puts "No mapping for #{@source} value: #{origval}"
            end
            row.delete(@source) if @del
            row
          end
        end
      end
    end
  end
end
