module Kiba
  module Extend
    module Transforms
      module Replace
        ::Replace = Kiba::Extend::Transforms::Replace
        class FieldValueWithStaticMapping
          def initialize(source:, target:, mapping:, fallback_val: :orig, delete_source: true)
            @source = source
            @target = target
            @mapping = mapping
            @mapping[nil] = nil unless @mapping.has_key?(nil)
            @fallback = fallback_val
            @del = delete_source
          end

          def process(row)
            origval = row.fetch(@source)
            if @mapping.has_key?(origval)
              row[@target] = @mapping[origval]
            else
              case @fallback
                when :orig
                  row[@target] = origval
              when :nil
                row[@target] = nil
              end
            end
            row.delete(@source) if @del
            row
          end
        end
      end
    end
  end
end
