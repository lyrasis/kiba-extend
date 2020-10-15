module Kiba
  module Extend
    module Transforms
      module Deduplicate
        ::Deduplicate = Kiba::Extend::Transforms::Deduplicate

        class Fields
          def initialize(source:, targets:, casesensitive: true, multival: false, sep: DELIM)
            @source = source
            @targets = targets
            @casesensitive = casesensitive
            @multival = multival
            @sep = sep
          end

          def process(row)
            sourceval = row.fetch(@source, nil)
            return row if sourceval.nil?
            targetvals = @targets.map{ |target| row.fetch(target, nil) }
            return row if targetvals.compact.empty?

            sourceval = @multival ? sourceval.split(@sep, -1).map{ |e| e.strip } : [sourceval.strip]
            if @multival
              targetvals = targetvals.map{ |val| val.split(@sep, -1).map{ |e| e.strip } }
            else
              targetvals = targetvals.map{ |val| [val.strip] }
            end

            if sourceval.blank?
              targetvals = targetvals.map{ |vals| vals.reject{ |e| e.blank? } }
            else
              if @casesensitive
                targetvals = targetvals.map{ |vals| vals - sourceval }
              else
                sourceval = sourceval.map{ |e| e.downcase }
                targetvals = targetvals.map{ |vals| vals.reject{ |val| sourceval.include?(val.downcase) } }
              end
            end
            
            if @multival
              targetvals = targetvals.map{ |vals| vals.join(@sep) unless vals.nil? }
            else
              targetvals = targetvals.map{ |vals| vals.first }
            end
            targetvals = targetvals.map{ |val| val.blank? ? nil : val  }

            targetvals.each_with_index{ |val, i| row[@targets[i]] = val }

            row
          end
        end
        
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

        class Flag
          def initialize(on_field:, in_field:, using:)
            @on = on_field
            @in = in_field
            @using = using
          end

          def process(row)
            val = row.fetch(@on)
            if @using.has_key?(val)
              row[@in] = 'y'
            else
              @using[val] = nil
              row[@in] = 'n'
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

            fv = row.fetch(@field, nil)
            unless fv.nil?
              if fv.empty?
                row[@field] = nil
                @other.each{ |f| row[f] = nil }
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
