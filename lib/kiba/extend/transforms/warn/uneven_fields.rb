# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Warn
        # @since 2.9.0
        #
        # rubocop:todo Layout/LineLength
        # Prints warning to STDOUT for each row having uneven values in the given fields
        # rubocop:enable Layout/LineLength
        #
        # ## What is meant by "Even fields"?
        #
        # rubocop:todo Layout/LineLength
        # When a field group is even, each field in the group contains the same number of values. For
        # rubocop:enable Layout/LineLength
        #   example:
        #
        # `{foo: 'af|bf|cf', bar: 'ab|bb|cb', baz: 'az|bz|cz'}`
        #
        # rubocop:todo Layout/LineLength
        # Depending on your application, an uneven field group may or may not be a concern:
        # rubocop:enable Layout/LineLength
        #
        # `{foo: 'af|bf|cf', bar: 'ab|bb|cb', baz: 'az|zz|bz|cz'}`
        #
        # rubocop:todo Layout/LineLength
        # `foo` and `bar` both have 3 values, while `baz` has 4. The assumption of a repeating
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   field group is: `foo[0]` goes with `bar[0]` goes with `baz[0]`, so having an extra value in
        # rubocop:enable Layout/LineLength
        #   `baz` is a problem if you expect `bf`, `bb`, and `bz` to line up.
        #
        # rubocop:todo Layout/LineLength
        # Note that the following is considered to be even, because we ignore fields that have no
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   value at all, and, though `baz` only has two values non-null values, the position of
        # rubocop:enable Layout/LineLength
        #   the null value in the middle is clearly indicated:
        #
        # `{foo: 'af|bf|cf', bar: nil, baz: 'az||cz'}`
        #
        # rubocop:todo Layout/LineLength
        # Several transforms have the option to automatically pad uneven value fields so that the overall
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   field group is even. However, there's no foolproof way to do this that will be correct for all
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   applications, so you should be able to get warnings for all instances of unevenness, in order
        # rubocop:enable Layout/LineLength
        #   to check your data is being transformed as expected.
        class UnevenFields
          include Helpers

          # rubocop:todo Layout/LineLength
          # @param fields [Array(Symbol)] fields across which to even field values
          # rubocop:enable Layout/LineLength
          # @param delim [String] used to split field values to determine length
          def initialize(fields:, delim: Kiba::Extend.delim)
            @fields = [fields].flatten
            @delim = delim
            @checker = Helpers::FieldEvennessChecker.new(fields: fields,
              delim: delim)
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            return row if fields.length == 1

            chk_result = checker.call(row)
            return row if chk_result == :even

            uneven = chk_result.map do |field, val|
              "#{field}: #{val}"
            end.join("; ")
            # rubocop:todo Layout/LineLength
            msg = "#{Kiba::Extend.warning_label}: Uneven values for #{fields.join("/")} in #{uneven}"
            # rubocop:enable Layout/LineLength
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
