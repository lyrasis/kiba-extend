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
      end # module Explode
    end #module Transforms
  end #module Extend
end #module Kiba
