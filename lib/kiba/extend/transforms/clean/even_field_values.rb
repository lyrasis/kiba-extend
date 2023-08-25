# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Clean
        # @since 2.9.0
        #
        # rubocop:todo Layout/LineLength
        # Ensures even field values across multiple fields (i.e. a field group) by appending some value to the end
        # rubocop:enable Layout/LineLength
        #   of fields containing fewer values.
        #
        # rubocop:todo Layout/LineLength
        # See explanation of "even fields" at {Kiba::Extend::Transforms::Warn::UnevenFields}
        # rubocop:enable Layout/LineLength
        #
        # rubocop:todo Layout/LineLength
        # This transform appends the value of `@evener` to field values as necessary to achieve
        # rubocop:enable Layout/LineLength
        #   evenness across fields. So, with `evener: '%NULLVALUE%'`:
        #
        # ```
        #  {a_foo: 'af', a_bar: 'ab', a_baz: 'az|zz'}
        # ```
        #
        # is transformed to:
        #
        # ```
        #   {a_foo: 'af|%NULLVALUE%', a_bar: 'ab|%NULLVALUE%', a_baz: 'az|zz'}
        # ```
        #
        # rubocop:todo Layout/LineLength
        # However, what if `af` and `ab` are intended to go with `zz` instead of `az`? Or what if, in this
        # rubocop:enable Layout/LineLength
        #   situation, you really want:
        #
        # ```
        #  {a_foo: 'af|af', a_bar: 'ab|ab', a_baz: 'az|zz'}
        # ```
        #
        # rubocop:todo Layout/LineLength
        # Only you can be sure, so, by default, you get a warning whenever a source gets padded to enforce
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   evenness. You can disable warnings by including `warn: false` in your transform set-up.
        # rubocop:enable Layout/LineLength
        #
        # ## Examples
        #
        # ### Default use
        #
        # Source data:
        #
        # ```
        # [
        #   {foo: 'a', bar: 'b', baz: 'c'},
        #   {foo: '', bar: nil, baz: 'c'},
        #   {foo: 'a|a|a', bar: '|b', baz: 'c'}
        # ]
        # ```
        #
        # Used as:
        #
        # ```
        # transform Clean::EvenFieldValues, fields: %i[foo bar baz], delim: '|'
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {foo: 'a', bar: 'b', baz: 'c'},
        #   {foo: '', bar: nil, baz: 'c'},
        # rubocop:todo Layout/LineLength
        #   {foo: 'a|a|a', bar: '|b|%NULLVALUE%', baz: 'c|%NULLVALUE%|%NULLVALUE%'}
        # rubocop:enable Layout/LineLength
        # ]
        # ```
        #
        # **NOTE:** nil or empty field values are skipped altogether
        #
        # ### Custom evener (String)
        #
        # Source data:
        #
        # ```
        # [
        #   {foo: 'a|a|a', bar: '|b', baz: 'c'}
        # ]
        # ```
        #
        # Used as:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # transform Clean::EvenFieldValues, fields: %i[foo bar baz], delim: '|', evener: '%BLANK%'
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {foo: 'a|a|a', bar: '|b|%BLANK%', baz: 'c|%BLANK%|%BLANK%'}
        # ]
        # ```
        #
        # ### Custom evener (:value)
        #
        # rubocop:todo Layout/LineLength
        # This setting causes the last value in the field before padding/evening the field  to be repeated
        # rubocop:enable Layout/LineLength
        #   as necessary to achieve evenness across fields in the group.
        #
        # Source data:
        #
        # ```
        # [
        #   {foo: '', bar: nil, baz: 'c'},
        #   {foo: 'a|a|a', bar: '|b', baz: 'c'},
        #   {foo: 'a|a|a', bar: 'b|', baz: 'c|a'}
        # ]
        # ```
        #
        # Used as:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # transform Clean::EvenFieldValues, fields: %i[foo bar baz], delim: '|', evener: :value
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {foo: '', bar: nil, baz: 'c'},
        #   {foo: 'a|a|a', bar: '|b|b', baz: 'c|c|c'},
        #   {foo: 'a|a|a', bar: 'b||', baz: 'c|a|a'},
        # ]
        # ```
        class EvenFieldValues
          # rubocop:todo Layout/LineLength
          # @param fields [Array(Symbol)] fields across which to even field values
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          # @param treat_as_null [nil, String, Array(String)] value(s) to treat as empty when determining if
          # rubocop:enable Layout/LineLength
          #   the entire field is empty or not
          # rubocop:todo Layout/LineLength
          # @param evener [String, :value] value used to even out uneven field values. If given a String, that
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   string will be appended to even out fields. If `:value`, the **final** value in the field needing
          # rubocop:enable Layout/LineLength
          #   evening will be repeated to even out the field.
          # @param delim [String] used to split/join multiple values in a field
          # rubocop:todo Layout/LineLength
          # @param warn [Boolean] whether to print warning of uneven fields to STDOUT
          # rubocop:enable Layout/LineLength
          def initialize(
            fields:,
            treat_as_null: Kiba::Extend.nullvalue,
            evener: Kiba::Extend.nullvalue,
            delim: Kiba::Extend.delim,
            warn: true
          )
            @fields = [fields].flatten
            @treat_as_null = treat_as_null.nil? ? [] : [treat_as_null].flatten
            @evener = evener
            @delim = delim
            @warn = warn

            @value_getter = Helpers::FieldValueGetter.new(fields: fields,
              treat_as_null: treat_as_null, delim: delim)
            @checker = Helpers::FieldEvennessChecker.new(fields: fields,
              delim: delim)
            @warner = Warn::UnevenFields.new(fields: fields, delim: delim)
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            return row if fields.length == 1

            chk = checker.call(row)
            return row if chk == :even

            warner.process(row) if warn
            max = find_max_vals(row)
            pad_uneven_values(row, chk, max)

            row
          end

          private

          attr_reader :fields, :treat_as_null, :evener, :delim, :warn,
            :value_getter, :checker, :warner

          def find_max_vals(row)
            value_getter.call(row)
              .values
              .map { |val| val.split(delim, -1) }
              .map(&:length)
              .max
          end

          def pad_uneven_value(row, field, val, max)
            vals = val.split(delim, -1)
            diff = max - vals.length
            pad = even_val(vals)
            diff.times { vals << pad }
            row[field] = vals.join(delim)
          end

          def pad_uneven_values(row, chk, max)
            chk.each { |field, val| pad_uneven_value(row, field, val, max) }
          end

          def even_val(val_ary)
            if evener == :value
              val_ary[-1]
            else
              evener
            end
          end
        end
      end
    end
  end
end
