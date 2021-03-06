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
        # collapse_on -- symbol -- default: :right -- on which end of the split array to join remaining split values
        #   if there are more than max_segments
        # warnfield -- symbol -- default: nil -- fieldname in which to put warning/error(s) for a row
        class IntoMultipleColumns
          def initialize(field:, sep:, delete_source: true, max_segments: 9999, collapse_on: :right, warnfield: nil)
            @field = field
            @sep = sep
            @del = delete_source
            @max = max_segments
            @collapse_on = collapse_on
            @warnfield = warnfield
          end

          def process(row)
            val = row.fetch(@field, nil)
            if val

              valsplit = val.split(@sep)

              if valsplit.size > @max && @warnfield
                row[@warnfield] = 'max_segments less than total number of split segments'
              elsif valsplit.size <= @max && @warnfield
                row[@warnfield] = nil
              end

              if valsplit.size <= @max
                process_splits(valsplit, row)
              else
                case @collapse_on
                when :right
                  process_splits(valsplit, row)
                when :left
                  process_left_split(valsplit, row)
                end
              end
              row.delete(@field) if @del
            end
            row
          end

          private

          def process_left_split(valsplit, row)
            diff = valsplit.size - @max
            leftside = []
            leftside << valsplit.shift until valsplit.size == diff
            row["#{@field}0".to_sym] = leftside.join(@sep).strip
            valsplit.each_with_index do |v, i|
              v = v.strip.empty? ? nil : v.strip
              row["#{@field}#{i + 1}".to_sym] = v
            end
          end
          
          def process_splits(valsplit, row)
            segments_remaining = []
            final_index = 0
            valsplit.each_with_index do |v, i|
              if i < @max - 1
                v = v.strip.empty? ? nil : v.strip
                row["#{@field}#{i}".to_sym] = v
                final_index = i
              else
                segments_remaining << v
              end
            end

            unless segments_remaining.empty?
              if segments_remaining.size == 1
                row["#{@field}#{final_index + 1}".to_sym] = segments_remaining[0].strip
              else
                val = segments_remaining.join(@sep)
                row["#{@field}#{final_index + 1}".to_sym] = val.strip
              end
            end

          end
        end
      end
    end
  end
end
