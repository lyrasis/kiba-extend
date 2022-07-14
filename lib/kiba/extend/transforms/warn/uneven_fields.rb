# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Warn
        # Prints warning to STDOUT for each row having uneven values in the given fields
        #
        # ## What is meant by "Even fields"?
        # 
        # When a field group is even, each field in the group contains the same number of values. For
        #   example:
        #
        #  {foo: 'af|bf|cf', bar: 'ab|bb|cb', baz: 'az|bz|cz'}
        #
        # Depending on your application, an uneven field group may or may not be a concern:
        #
        #  {foo: 'af|bf|cf', bar: 'ab|bb|cb', baz: 'az|zz|bz|cz'}
        #
        # `foo` and `bar` both have 3 values, while `baz` has 4. The assumption of a repeating
        #   field group is: `foo[0]` goes with `bar[0]` goes with `baz[0]`, so having an extra value in
        #   `baz` is a problem if you expect `bf`, `bb`, and `bz` to line up.
        #
        # Several transforms have the option to automatically pad uneven value fields so that the overall
        #   field group is even. However, there's no foolproof way to do this that will be correct for all
        #   applications, so you should be able to get warnings for all instances of unevenness, in order
        #   to check your data is being transformed as expected.
        class UnevenFields
          include Helpers

          # @param fields [Array(Symbol)] fields across which to even field values
          # @param delim [String] used to split field values to determine length
          def initialize(fields:, delim: Kiba::Extend.delim)
            @fields = [fields].flatten
            @delim = delim
            @checker = Helpers::RowFieldEvennessChecker.new(fields: fields, delim: delim)
          end
          
          # @private
          def process(row)
            return row if fields.length == 1

            chk_result = checker.call(row)
            return row if chk_result == :even

            uneven = chk_result.map{ |field, val| "#{field}: #{val}" }.join('; ')
            msg = "#{Kiba::Extend.warning_label}: Uneven values for #{fields.join('/')} in #{uneven}"
            warn(msg)
            row
          end

          private

          attr_reader :fields, :delim, :checker
        end
      end
    end
  end
end