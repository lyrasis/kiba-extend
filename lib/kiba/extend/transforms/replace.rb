# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transformations that perform replacements of full field values
      #
      # For finding/replacing within field values, see {Clean::RegexpFindReplaceFieldVals}
      module Replace
        ::Replace = Kiba::Extend::Transforms::Replace

        class FieldValueWithStaticMapping
          def initialize(source:, target:, mapping:, fallback_val: :orig, delete_source: true,
                         multival: false, sep: '')
            @source = source
            @target = target
            @mapping = mapping
            @mapping[nil] = nil unless @mapping.key?(nil)
            @fallback = fallback_val
            @del = delete_source
            @multival = multival
            @sep = sep
          end

          # @private
          def process(row)
            rowval = row.fetch(@source, nil)
            origval = if rowval.nil?
                        [rowval]
                      else
                        @multival ? row.fetch(@source).split(@sep) : [row.fetch(@source)]
                      end
            newvals = []

            origval.each do |oval|
              newvals << if @mapping.key?(oval)
                           @mapping[oval]
                         else
                           case @fallback
                           when :orig
                             oval
                           when :nil
                             nil
                           else
                             @fallback
                           end
                         end
            end

            row[@target] = newvals.length > 1 ? newvals.join(@sep) : newvals.first
            row.delete(@source) if @source != @target && @del
            row
          end
        end
      end
    end
  end
end
