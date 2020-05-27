module Kiba
  module Extend
    module Transforms
      module Deduplicate
        ::Deduplicate = Kiba::Extend::Transforms::Deduplicate

        class MultiFieldValues
          def initialize(field:, sep:)
            @field = field
            @sep = sep
          end

          def process(row)
            val = row.fetch(@field)
            row[@field] = val.split(@sep).uniq.join(@sep) unless val.nil?
            row
          end
        end
      end
    end
  end
end
