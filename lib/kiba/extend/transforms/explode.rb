module Kiba
  module Extend
    module Transforms
      module Explode
        ::Explode = Kiba::Extend::Transforms::Explode

        # Given a row like:
        # | :id | :r1 | :r2     |
        # | 001 | a;b | foo;bar |
        # And told to split on :r1 with delimiter ';', returns:
        # | 001 | a | foo;bar |
        # | 001 | b | foo;bar |
        class RowsFromMultivalField
          def initialize(field:, delim:)
            @field = field
            @delim = delim
          end

          def process(row)
            other_fields = row.keys.reject{ |k| k == @field }
            fieldval = row.fetch(@field, nil)
            fieldval = fieldval.nil? ? [] : fieldval.split(@delim)
            if fieldval.size > 1
              fieldval.each do |val|
                rowcopy = row.clone
                other_fields.each{ |f| rowcopy[f] = rowcopy.fetch(f, nil) }
                rowcopy[@field] = val
                yield(rowcopy)
              end
              nil
            else
              row
            end
          end
        end

        # Given a row like:
        # | :id | :r1 | :r2     | :ra | :rb | :xq |
        # | 001 | a;b | foo;bar | aa  | bb  | eee |
        # And told to explode columns :ra and :rb to new row, can create:
        # | 001 | :a1 | :b2     | :xq |
        # | 001 | a;b | foo;bar | eee |
        # | 001 | aa  | bb      | eee |
        class ColumnsRemappedInNewRows
          def initialize(remap_groups:, map_to:)
            @groups = remap_groups
            @map = map_to
          end

          def process(row)
            other_fields = row.keys - @groups.flatten
            @groups.each do |group|
              rowcopy = row.clone
              this = {}
              other_fields.each{ |f| this[f] = rowcopy.fetch(f, nil) }
              group.each_with_index do |f, i|
                this[@map[i]] = rowcopy.fetch(f, nil)
              end
              yield(this)
            end
            nil
          end
        end

        class FieldValuesToNewRows
          def initialize(fields: [], target:, multival: false, sep: ' ', keep_nil: false, keep_empty: false)
            @fields = fields
            @target = target
            @multival = multival
            @sep = sep
            @keep_nil = keep_nil
            @keep_empty = keep_empty
          end

          def process(row)
            rows = []
            other_fields = row.keys - @fields
            other_data = {}
            other_fields.each{ |f| other_data[f] = row.fetch(f, nil) }

            @fields.each do |field|
              val = row.fetch(field, nil)
              if val.nil?
                vals = [nil]
              elsif val.empty?
                vals = ['']
              elsif @multival
                vals = val.split(@sep, -1)
              else
                vals = [val]
              end

              vals.each do |val|
                next if val.nil? unless @keep_nil
                next if val.empty? unless val.nil? || @keep_empty
                new_row = other_data.clone
                new_row[@target] = val
                rows << new_row
              end
            end
            rows.each{ |r| yield(r) }
            nil
          end
        end

      end # module Explode
    end #module Transforms
  end #module Extend
end #module Kiba
