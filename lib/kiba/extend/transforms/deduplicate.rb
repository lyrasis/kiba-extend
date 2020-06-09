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

        class GroupedFieldValues
          def initialize(on_field:, grouped_fields: [], sep:)
            @field = on_field
            @other = grouped_fields
            @sep = sep
          end

          def process(row)
            fv = row.fetch(@field)
            seen = []
            delete = []
            unless fv.nil?
              fv = fv.split(@sep)
              valfreq = get_value_frequency(fv)
              fv.each_with_index do |val, i|
                if valfreq[val] > 1
                  if seen.include?(val)
                    delete << i
                  else
                    seen << val
                  end
                end
              end
              row[@field] = fv.uniq.join(@sep)

              if delete.size > 0
                delete = delete.sort.reverse
                h = {}
                @other.each{ |of| h[of] = row.fetch(of) }
                h = h.reject{ |f, val| val.nil? }.to_h
                h.each{ |f, val| h[f] = val.split(@sep) }
                h.each do |f, val|
                  delete.each{ |i| val.delete_at(i) }
                  val.size > 0 ? row[f] = val.join(@sep) : row[f] = nil
                end
              end
            end
            row
          end

          private

          def get_value_frequency(fv)
            h = {}
            fv.uniq.each{ |v| h[v] = 0 }
            fv.uniq{ |v| h[v] += 1 }
            h
          end
        end
        
      end
    end
  end
end
