# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Explode
        class FieldValuesToNewRows
          def initialize(target:, fields: [], multival: false, sep: " ",
            keep_nil: false, keep_empty: false)
            @fields = [fields].flatten
            @target = target
            @multival = multival
            @sep = sep
            @keep_nil = keep_nil
            @keep_empty = keep_empty
          end

          def process(row, &)
            rows = []
            other_fields = row.keys - @fields
            other_data = {}
            other_fields.each { |f| other_data[f] = row.fetch(f, nil) }

            @fields.each do |field|
              val = row.fetch(field, nil)
              vals = if val.nil?
                [nil]
              elsif val.empty?
                [""]
              elsif @multival
                val.split(@sep, -1)
              else
                [val]
              end

              vals.each do |val|
                next if !@keep_nil && val.nil?
                next if !(val.nil? || @keep_empty) && val.empty?

                new_row = other_data.clone
                new_row[@target] = val
                rows << new_row
              end
            end
            rows.each(&)
            nil
          end
        end
      end
    end
  end
end
