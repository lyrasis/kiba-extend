# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Reshape
        # @since 2.9.0
        #
        # rubocop:todo Layout/LineLength
        # Convenience transform to rename one or more fields and add a field with a constant value,
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   by default ensuring explicit empty field values and field evenness expected in
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   field groups. Runs the following other transforms, which you will want to understand
        # rubocop:enable Layout/LineLength
        #   before using this one:
        #
        # - {Rename::Fields}
        # - {Replace::EmptyFieldValues}
        # - {Clean::EvenFieldValues}
        # - {Delete::EmptyFieldGroups}
        #
        # ## Examples
        #
        # Source data:
        #
        # ```
        # [
        #   {note: 'foo', date: '2022'},
        #   {note: nil, date: '2022'},
        #   {note: 'foo', date: nil},
        #   {note: '', date: nil},
        #   {note: 'foo|bar|baz', date: '2022|2021'},
        #   {note: 'foo|bar', date: nil},
        #   {note: 'foo|bar|baz', date: '2022||2021'},
        #   {note: '|bar|baz', date: '2022|2021'},
        #   {note: 'foo|bar|', date: '2022|2021'},
        # ]
        # ```
        #
        # rubocop:todo Layout/LineLength
        # Value of `Kiba::Extend.nullvalue` = `'%NULLVALUE%'`. Value of `Kiba::Extend.delim` = `'|'`.
        # rubocop:enable Layout/LineLength
        #
        # ### Default behavior
        #
        # Used in job as:
        #
        # ```
        # transform Reshape::FieldsToFieldGroupWithConstant,
        #   fieldmap: {note: :a_note, date: :a_date},
        #   constant_target: :a_type,
        #   constant_value: 'a thing'
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {a_type: 'a thing', a_note: 'foo', a_date: '2022'},
        #   {a_type: 'a thing', a_note: nil, a_date: '2022'},
        #   {a_type: 'a thing', a_note: 'foo', a_date: nil},
        #   {a_type: nil, a_note: nil, a_date: nil},
        # rubocop:todo Layout/LineLength
        #   {a_type: 'a thing|a thing|a thing', a_note: 'foo|bar|baz', a_date: '2022|2021|%NULLVALUE%'},
        # rubocop:enable Layout/LineLength
        #   {a_type: 'a thing|a thing', a_note: 'foo|bar', a_date: nil},
        # rubocop:todo Layout/LineLength
        #   {a_type: 'a thing|a thing|a thing', a_note: 'foo|bar|baz', a_date: '2022|%NULLVALUE%|2021'},
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   {a_type: 'a thing|a thing|a thing', a_note: '%NULLVALUE%|bar|baz', a_date: '2022|2021|%NULLVALUE%'},
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   {a_type: 'a thing|a thing|a thing', a_note: 'foo|bar|%NULLVALUE%', a_date: '2022|2021|%NULLVALUE%'}
        # rubocop:enable Layout/LineLength
        # ]
        # ```
        #
        # ### With custom `treat_as_null` string
        #
        # Used in job as:
        #
        # ```
        # transform Reshape::FieldsToFieldGroupWithConstant,
        #   fieldmap: {note: :a_note, date: :a_date},
        #   constant_target: :a_type,
        #   constant_value: 'a thing',
        #   treat_as_null: '%BLANK%'
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {a_type: 'a thing', a_note: 'foo', a_date: '2022'},
        #   {a_type: 'a thing', a_note: nil, a_date: '2022'},
        #   {a_type: 'a thing', a_note: 'foo', a_date: nil},
        #   {a_type: nil, a_note: nil, a_date: nil},
        # rubocop:todo Layout/LineLength
        #   {a_type: 'a thing|a thing|a thing', a_note: 'foo|bar|baz', a_date: '2022|2021|%BLANK%'},
        # rubocop:enable Layout/LineLength
        #   {a_type: 'a thing|a thing', a_note: 'foo|bar', a_date: nil},
        # rubocop:todo Layout/LineLength
        #   {a_type: 'a thing|a thing|a thing', a_note: 'foo|bar|baz', a_date: '2022|%BLANK%|2021'},
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   {a_type: 'a thing|a thing|a thing', a_note: '%BLANK%|bar|baz', a_date: '2022|2021|%BLANK%'},
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   {a_type: 'a thing|a thing|a thing', a_note: 'foo|bar|%BLANK%', a_date: '2022|2021|%BLANK%'}
        # rubocop:enable Layout/LineLength
        # ]
        # ```
        #
        # rubocop:todo Layout/LineLength
        # ### With `evener: :value` (repeat final value of field to even out field values)
        # rubocop:enable Layout/LineLength
        #
        # Used in job as:
        #
        # ```
        # transform Reshape::FieldsToFieldGroupWithConstant,
        #   fieldmap: {note: :a_note, date: :a_date},
        #   constant_target: :a_type,
        #   constant_value: 'a thing',
        #   evener: :value
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {a_type: 'a thing', a_note: 'foo', a_date: '2022'},
        #   {a_type: 'a thing', a_note: nil, a_date: '2022'},
        #   {a_type: 'a thing', a_note: 'foo', a_date: nil},
        #   {a_type: nil, a_note: nil, a_date: nil},
        # rubocop:todo Layout/LineLength
        #   {a_type: 'a thing|a thing|a thing', a_note: 'foo|bar|baz', a_date: '2022|2021|2021'},
        # rubocop:enable Layout/LineLength
        #   {a_type: 'a thing|a thing', a_note: 'foo|bar', a_date: nil},
        # rubocop:todo Layout/LineLength
        #   {a_type: 'a thing|a thing|a thing', a_note: 'foo|bar|baz', a_date: '2022|%NULLVALUE%|2021'},
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   {a_type: 'a thing|a thing|a thing', a_note: '%NULLVALUE%|bar|baz', a_date: '2022|2021|2021'},
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   {a_type: 'a thing|a thing|a thing', a_note: 'foo|bar|%NULLVALUE%', a_date: '2022|2021|2021'}
        # rubocop:enable Layout/LineLength
        # ]
        # ```
        #
        # ### With `enforce_evenness: false`
        #
        # Used in job as:
        #
        # ```
        # transform Reshape::FieldsToFieldGroupWithConstant,
        #   fieldmap: {note: :a_note, date: :a_date},
        #   constant_target: :a_type,
        #   constant_value: 'a thing',
        #   enforce_evenness: false
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {a_type: 'a thing', a_note: 'foo', a_date: '2022'},
        #   {a_type: 'a thing', a_note: nil, a_date: '2022'},
        #   {a_type: 'a thing', a_note: 'foo', a_date: nil},
        #   {a_type: nil, a_note: nil, a_date: nil},
        # rubocop:todo Layout/LineLength
        #   {a_type: 'a thing|a thing|a thing', a_note: 'foo|bar|baz', a_date: '2022|2021'},
        # rubocop:enable Layout/LineLength
        #   {a_type: 'a thing|a thing', a_note: 'foo|bar', a_date: nil},
        # rubocop:todo Layout/LineLength
        #   {a_type: 'a thing|a thing|a thing', a_note: 'foo|bar|baz', a_date: '2022|%NULLVALUE%|2021'},
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   {a_type: 'a thing|a thing|a thing', a_note: '%NULLVALUE%|bar|baz', a_date: '2022|2021'},
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   {a_type: 'a thing|a thing|a thing', a_note: 'foo|bar|%NULLVALUE%', a_date: '2022|2021'}
        # rubocop:enable Layout/LineLength
        # ]
        # ```
        #
        # ### With `treat_as_null: nil` and `evener: '%NULL%`
        #
        # Used in job as:
        #
        # ```
        # transform Reshape::FieldsToFieldGroupWithConstant,
        #   fieldmap: {note: :a_note, date: :a_date},
        #   constant_target: :a_type,
        #   constant_value: 'a thing',
        #   treat_as_null: nil,
        #   evener: '%NULL%'
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {a_type: 'a thing', a_note: 'foo', a_date: '2022'},
        #   {a_type: 'a thing', a_note: nil, a_date: '2022'},
        #   {a_type: 'a thing', a_note: 'foo', a_date: nil},
        #   {a_type: nil, a_note: nil, a_date: nil},
        # rubocop:todo Layout/LineLength
        #   {a_type: 'a thing|a thing|a thing', a_note: 'foo|bar|baz', a_date: '2022|2021|%NULL%'},
        # rubocop:enable Layout/LineLength
        #   {a_type: 'a thing|a thing', a_note: 'foo|bar', a_date: nil},
        # rubocop:todo Layout/LineLength
        #   {a_type: 'a thing|a thing|a thing', a_note: 'foo|bar|baz', a_date: '2022||2021'},
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   {a_type: 'a thing|a thing|a thing', a_note: '|bar|baz', a_date: '2022|2021|%NULL%'},
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   {a_type: 'a thing|a thing|a thing', a_note: 'foo|bar|', a_date: '2022|2021|%NULL%'}
        # rubocop:enable Layout/LineLength
        # ]
        # ```
        class FieldsToFieldGroupWithConstant
          # rubocop:todo Layout/LineLength
          # @param fieldmap [Hash{Symbol => Symbol}] map for renaming existing fields. Keys: existing field
          # rubocop:enable Layout/LineLength
          #   names. Values: new field names. Forwarded to {Rename::Fields}
          # rubocop:todo Layout/LineLength
          # @param constant_target [Symbol] new field that will be added to contain constant value
          # rubocop:enable Layout/LineLength
          # @param constant_value [String] value used to populate constant field
          # rubocop:todo Layout/LineLength
          # @param replace_empty [Boolean] whether to run {Replace::EmptyFieldValues}
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          # @param treat_as_null [nil, String, Array(String)] value(s) to be treated as empty when replacing
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   empty field values and deleting empty field groups. If `nil`, '' will be used. **NOTE:** If you
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   need different `treat_as_null` values for replacing empty field values and deleting empty field
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   groups, use {Replace::EmptyFieldValues} separately in your job before you use this transform.
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          # @param enforce_evenness [Boolean] whether to pad field values to ensure all resulting fields have
          # rubocop:enable Layout/LineLength
          #   the same number of values
          # rubocop:todo Layout/LineLength
          # @param evener [String, :value, nil] value used to even out uneven field values. If given a String,
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   that string will be appended to even out fields. If `nil`, the value of `treat_as_null` will be
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   used. If `:value`, the **final** value in the field will be repeated to even out the field.
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          # @param uneven_warning [Boolean] whether to print warnings about uneven field groups to STDOUT
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          # @param remove_empty_groups [Boolean] whether to run {Delete::EmptyFieldGroups} before finalizing row
          # rubocop:enable Layout/LineLength
          # @param delim [String] used to split/join multiple values in a field
          # rubocop:todo Layout/LineLength
          def initialize(fieldmap:, constant_target:, constant_value:, delim: Kiba::Extend.delim,
            # rubocop:enable Layout/LineLength
            replace_empty: true, treat_as_null: Kiba::Extend.nullvalue,
            enforce_evenness: true, evener: nil, uneven_warning: true,
            remove_empty_groups: true)
            @renamer = Rename::Fields.new(fieldmap: fieldmap)
            @renamed = fieldmap.values
            @target = constant_target
            @value = constant_value
            @delim = delim
            @replace_empty = replace_empty
            @treat_as_null = treat_as_null.nil? ? "" : treat_as_null
            @enforce_evenness = enforce_evenness
            @evener = evener.nil? ? treat_as_null : evener
            @uneven_warning = uneven_warning
            @remove_empty_groups = remove_empty_groups

            # rubocop:todo Layout/LineLength
            @empty_replacer = Replace::EmptyFieldValues.new(fields: @renamed, value: treat_as_null, delim: delim,
              # rubocop:enable Layout/LineLength
              treat_as_null: treat_as_null)
            # rubocop:todo Layout/LineLength
            @even_xform = Clean::EvenFieldValues.new(fields: @renamed, evener: @evener, delim: delim,
              # rubocop:enable Layout/LineLength
              warn: uneven_warning)
            @group_cleaner = Delete::EmptyFieldGroups.new(
              groups: [[renamed,
                target].flatten], delim: delim, treat_as_null: treat_as_null
            )
            @value_getter = Helpers::FieldValueGetter.new(fields: renamed,
              delim: delim, treat_as_null: treat_as_null)
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            renamer.process(row)
            empty_replacer.process(row) if replace_empty
            max_vals = find_max_vals(row)
            add_constant(row, max_vals)
            even_xform.process(row) if enforce_evenness
            group_cleaner.process(row) if remove_empty_groups
          end

          private

          attr_reader :renamer, :renamed, :target, :value, :delim,
            :replace_empty, :treat_as_null, :empty_replacer,
            :enforce_evenness, :evener, :even_xform,
            :remove_empty_groups, :group_cleaner,
            :value_getter

          def add_constant(row, max)
            row[target] = if max
              Array.new(max, value).join(delim)
            end
          end

          def find_max_vals(row)
            if renamed.length == 1
              val = row[renamed.first]
              return 0 if val.blank?

              val.split(delim, -1).length
            else
              value_getter.call(row)
                .values
                .map { |val| val.split(delim, -1) }
                .map(&:length)
                .max
            end
          end

          def even_renamed_field(field, row, max)
            value = row[field]
            return if value.blank?

            split = value.split(delim, -1)
            len = split.length
            return if len == max

            diff = max - len
            diff.times { split << even_val(split) }
            row[field] = split.join(delim)
          end

          def even_renamed_fields(row, max)
            renamed.each { |field| even_renamed_field(field, row, max) }
          end

          def even_val(val_ary)
            if evener == :value
              val_ary[-1]
            else
              evener
            end
          end

          def replace_empty_values(row)
            renamed.each { |field| replace_empty_values_in_field(field, row) }
          end

          def replace_empty_values_in_field(field, row)
            val = row[field]
            return if val.blank?

            split = val.split(delim, -1)
            return unless split.any? { |val| val.blank? }

            row[field] = split.map do |val|
              val.blank? ? treat_as_null : val
            end.join(delim)
          end
        end
      end
    end
  end
end
