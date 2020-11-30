module Kiba
  module Extend
    module Transforms
      module Replace
        ::Replace = Kiba::Extend::Transforms::Replace
        class EmptyFieldValues
          def initialize(fields:, value:)
            @fields = fields
            @value = value
          end

          def process(row)
            blankfields = @fields.map{ |field| [field, row.fetch(field, nil)] }
              .select{ |pair| pair[1].blank? }
              .map{ |pair| pair[0] }
            return row if blankfields.empty?
            blankfields.each{ |field| row[field] = @value }
            row
          end
        end
        
        class FieldValueWithStaticMapping
          def initialize(source:, target:, mapping:, fallback_val: :orig, delete_source: true,
                         multival: false, sep: '')
            @source = source
            @target = target
            @mapping = mapping
            @mapping[nil] = nil unless @mapping.has_key?(nil)
            @fallback = fallback_val
            @del = delete_source
            @multival = multival
            @sep = sep
          end

          def process(row)
            rowval = row.fetch(@source, nil)
            if rowval.nil?
              origval = [rowval]
            else
              origval = @multival ? row.fetch(@source).split(@sep) : [row.fetch(@source)]
            end
            newvals = []
            
            origval.each do |oval|
              if @mapping.has_key?(oval)
                newvals << @mapping[oval]
              else
                case @fallback
                when :orig
                  newvals << oval
                when :nil
                  newvals << nil
                else
                  newvals << @fallback
                end
              end
            end

            row[@target] =  newvals.length > 1 ? newvals.join(@sep) : newvals.first
            row.delete(@source) if @del unless @source == @target
            row
          end
        end
      end
    end
  end
end
