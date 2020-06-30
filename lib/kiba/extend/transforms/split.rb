module Kiba
  module Extend
    module Transforms
      module Split
        ::Split = Kiba::Extend::Transforms::Split

        # Splits field into multiple fields, based on sep
        # New columns will use original field name, and add number to end (:field0, :field1, etc)
        # sep -- string -- string on which to split
        # delete_source -- boolean -- default: true -- If true, removes original field. If false, leaves original field
        # max_segments -- integer -- default: 9999 (represents unlimited) -- optionally specifify maximum number
        #   of segments to split into (i.e. max number of columns to create from this one column). Values farther
        #   to the right will be joined back together and included in final column
        # warnfield -- symbol -- default: nil -- fieldname in which to put warning/error(s) for a row
        class IntoMultipleColumns
          def initialize(field:, sep:, delete_source: true, max_segments: 9999, warnfield: nil)
            @field = field
            @sep = sep
            @del = delete_source
            @max = max_segments
            @warnfield = warnfield
          end

          def process(row)
            val = row.fetch(@field, nil)
            if val
              segments_remaining = []
              final_index = 0
              val.split(@sep).each_with_index do |v, i|
                if i < @max - 1
                  v = v.strip.empty? ? nil : v.strip
                  row["#{@field}#{i}".to_sym] = v
                  final_index = i
                else
                  segments_remaining << v
                end
              end
              unless segments_remaining.empty?
                val = segments_remaining.join(@sep)
                row["#{@field}#{final_index + 1}".to_sym] = val.strip
                unless @warnfield.nil?
                  row[@warnfield] = 'max_segments less than total number of split segments'
                end
              end
              
              row.delete(@field) if @del
            end
            row
          end
        end
      end
    end
  end
end
