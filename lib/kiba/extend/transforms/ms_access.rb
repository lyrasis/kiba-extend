require 'bigdecimal'

module Kiba
  module Extend
    module Transforms
      module MsAccess
        ::MsAccess = Kiba::Extend::Transforms::MsAccess
        class ScientificNotationToNumberString
          def initialize(fields:)
            @fields = fields
          end

          def process(row)
            @fields.each{ |field| process_field(row, field) }
            row
          end

          private
          
          def process_field(row, field)
            value = row[field]
            return if value.blank?
            return unless value.match?(/[Ee][-+]/)
            row[field] = BigDecimal(value).to_s.sub(/\.0+$/, '')
              #"%f" % value
          end
        end
      end
    end
  end
end
