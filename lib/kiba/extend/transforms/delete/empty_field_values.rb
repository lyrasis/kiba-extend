# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Tranformations to delete fields and field values
      module Delete
        class EmptyFieldValues
          def initialize(fields:, sep:, usenull: false)
            @fields = [fields].flatten
            @sep = sep
            @usenull = usenull
          end

          # @private

          def process(row)
            fields.each do |field|
              val = row.fetch(field)
              next if val.nil?
              
              row[field] = val.split(sep)
                .compact
                .reject{ |str| Helpers.empty?(str, usenull) }
                .join(sep)
            end
            row
          end

          private

          attr_reader :fields, :sep, :usenull
        end
      end
    end
  end
end
