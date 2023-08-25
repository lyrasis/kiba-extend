# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Helpers
        # @since 2.9.0
        #
        # rubocop:todo Layout/LineLength
        # Given row and array of field names, checks whether fields have the same number of values
        # rubocop:enable Layout/LineLength
        class FieldEvennessChecker
          def initialize(fields:, delim: Kiba::Extend.delim)
            @fields = [fields].flatten
            @delim = delim
            @value_getter = FieldValueGetter.new(fields: fields, delim: delim)
          end

          def call(row)
            return :even if fields.length == 1

            vals = value_getter.call(row)
            max = max_value_ct(vals)
            checked = vals.map { |field, val|
              [field, (val.split(delim, -1).length == max) ? :even : :uneven]
            }
              .to_h
            return :even if checked.values.all?(:even)

            vals.select { |field, value| checked[field] == :uneven }
          end

          private

          attr_reader :fields, :delim, :value_getter

          def max_value_ct(vals)
            vals.dup
              .values
              .map { |val| val.split(delim, -1) }
              .map(&:length)
              .max
          end

          def is_even?(source)
            chk = valhash.map { |_target, sources|
              sources[source].compact.length
            }
              .uniq
            return true if chk.length == 1

            source
          end
        end
      end
    end
  end
end
