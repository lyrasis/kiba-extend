# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Clean
        # Ensures even field values across multiple fields (i.e. a field group) by appending some value to the end
        #   of fields containing fewer values.
        #
        # See explanation of "even fields" at {Kiba::Extend::Transforms::Warn::UnevenFields}
        #
        # This transform appends the value of `@evener` to field values as necessary to achieve
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
        # However, what if `af` and `ab` are intended to go with `zz` instead of `az`? Or what if, in this
        #   situation, you really want:
        #
        # ```
        #  {a_foo: 'af|af', a_bar: 'ab|ab', a_baz: 'az|zz'}
        # ```
        #
        # Only you can be sure, so, by default, you get a warning whenever a source gets padded to enforce
        #   evenness. You can disable warnings by including `warn: false` in your transform set-up.
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
        #   {foo: 'a|a|a', bar: '|b|%NULLVALUE%', baz: 'c|%NULLVALUE%|%NULLVALUE%'}
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
        # transform Clean::EvenFieldValues, fields: %i[foo bar baz], delim: '|', evener: '%BLANK%'
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
        # This setting causes the last value in the field before padding/evening the field  to be repeated
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
        # transform Clean::EvenFieldValues, fields: %i[foo bar baz], delim: '|', evener: :value
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
          # @param fields [Array(Symbol)] fields across which to even field values
          # @param treat_as_null [nil, String, Array(String)] value(s) to treat as empty when determining if
          #   the entire field is empty or not
          # @param evener [String, :value] value used to even out uneven field values. If given a String, that
          #   string will be appended to even out fields. If `:value`, the **final** value in the field needing
          #   evening will be repeated to even out the field.
          # @param delim [String] used to split/join multiple values in a field
          # @param warn [Boolean] whether to print warning of uneven fields to STDOUT
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
            
            @value_getter = Helpers::FieldValueGetter.new(fields: fields, treat_as_null: treat_as_null, delim: delim)
            @checker = Helpers::RowFieldEvennessChecker.new(fields: fields, delim: delim)
            @warner = Warn::UnevenFields.new(fields: fields, delim: delim)
          end
          
          # @private
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

          attr_reader :fields, :treat_as_null, :evener, :delim, :warn, :value_getter, :checker, :warner

          def find_max_vals(row)
            value_getter.call(row)
              .values
              .map{ |val| val.split(delim, -1) }
              .map(&:length)
              .max
          end

          def pad_uneven_value(row, field, val, max)
            vals = val.split(delim, -1)
            diff = max - vals.length
            pad = even_val(vals)
            diff.times{ vals << pad }
            row[field] = vals.join(delim)
          end
          
          def pad_uneven_values(row, chk, max)
            chk.each{ |field, val| pad_uneven_value(row, field, val, max) }
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
