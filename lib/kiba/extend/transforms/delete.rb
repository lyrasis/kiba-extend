# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Tranformations to delete fields and field values
      module Delete
        ::Delete = Kiba::Extend::Transforms::Delete          
        class FieldValueIfEqualsOtherField
          def initialize(delete:, if_equal_to:, multival: false, sep: nil, grouped_fields: [], case_sensitive: true)
            @delete = delete
            @compare = if_equal_to
            @multival = multival
            @sep = sep
            @group = grouped_fields
            @case_sensitive = case_sensitive
          end

          # @private
          def process(row)
            comparefield = @case_sensitive ? row.fetch(@compare) : row.fetch(@compare).downcase
            fv = row.fetch(@delete)
            unless fv.nil?
              fv = @multival ? fv.split(@sep) : [fv]
              fvcompare = @case_sensitive ? fv : fv.map(&:downcase)
              result = []
              deleted = []
              fvcompare.each_with_index do |val, i|
                if val == comparefield
                  result << nil
                  deleted << i
                else
                  result << fv[i]
                end
                row[@delete] = result.compact.join(@sep)
              end
              @group.each do |gf|
                gfval = row.fetch(gf)
                next if gfval.nil?

                gfvals = gfval.split(@sep)
                deleted.sort.reverse.each { |i| gfvals.delete_at(i) }
                row[gf] = gfvals.join(@sep)
              end
            end
            row
          end
        end
      end
    end
  end
end
