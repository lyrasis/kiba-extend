module Kiba
  module Extend
    module Transforms
      module Deduplicate
        ::Deduplicate = Kiba::Extend::Transforms::Deduplicate

        class FieldValues
          def initialize(fields:, sep:)
            @fields = fields
            @sep = sep
          end

          def process(row)
            @fields.each do |field|
              val = row.fetch(field)
              row[field] = val.split(@sep).uniq.join(@sep) unless val.nil?
            end
            row
          end
        end
      end
    end
  end
end
