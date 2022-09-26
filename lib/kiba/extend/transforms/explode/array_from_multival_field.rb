module Kiba
  module Extend
    module Transforms
      module Explode
      
        # Splits given field value into an array on given delimiter.
          #
          # # Examples
          #
          # Input table:
          # ```
          # | r1  | r2      |
          # |-----+---------|
          # | a;b | foo;bar |
          # ```
          #
          # Used in pipeline as:
          #
          # ```
          # transform Explode::ArrayFromMultivalField, field: :r1, delim: ';'
          # ```
          #
          # Results in:
          #
          # ```
          # | r1 | r2      |
          # |----+---------|
          # | [a,b] | foo;bar |
          # ```
          #
        class ArrayFromMultivalField
          def initialize(field:, delim: nil)
            @field = field
            @delim = delim ||= Kiba::Extend.delim
          end

          def process(row)
            fieldval = row.fetch(@field, nil)
            row[@field] = fieldval.nil? ? [] : fieldval.split(@delim)

            row
          end
        end
      end
    end
  end
end