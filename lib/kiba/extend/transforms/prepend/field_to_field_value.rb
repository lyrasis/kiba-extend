# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Prepend
        # rubocop:todo Layout/LineLength
        # Adds the value of `prepended_field` to the beginning of the value(s) of the `target_field`
        # rubocop:enable Layout/LineLength
        #
        # rubocop:todo Layout/LineLength
        # If target field value is blank, it is left blank, even if there is a prepended field value.
        # rubocop:enable Layout/LineLength
        #   If there is no value in prepended field, target field is left as-is
        #
        # # Examples
        #
        # Used in pipeline as:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # transform Prepend::FieldToFieldValue, target_field: :a, prepended_field: :b, sep: ': '
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Input table:
        #
        # ```
        # | a     | b   |
        # |-------+-----|
        # | c     | d   |
        # | e;f   | g   |
        # |       | h   |
        # | i     |     |
        # | j;k   | l;m |
        # | o;p;q | r;s |
        # | ;t    | u;v
        # ```
        #
        # Results in:
        #
        # ```
        # | a          | b   |
        # |------------|-----|
        # | d: c       | d   |
        # | g: e;f     | g   |
        # |            | h   |
        # | i          |     |
        # | l;m: j;k   | l;m |
        # | r;s: o;p;q | r;s |
        # | u;v: ;t    | u;v |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # transform Prepend::FieldToFieldValue, target_field: :a, prepended_field: :b, sep: ': ',
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #                                        delete_prepended: true, mvdelim: ';'
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Input table:
        #
        # ```
        # | a     | b   |
        # |-------+-----|
        # | c     | d   |
        # | e;f   | g   |
        # |       | h   |
        # | i     |     |
        # | j;k   | l;m |
        # | o;p;q | r;s |
        # | ;t    | u;v
        # ```
        #
        # Results in:
        #
        # ```
        # | a                    |
        # |----------------------|
        # | d: c                 |
        # | g: e;g: f            |
        # |                      |
        # | i                    |
        # | l;m: j;l;m: k        |
        # | r;s: o;r;s: p;r;s: q |
        # | ;u;v: t              |
        # ```
        #
        # rubocop:todo Layout/LineLength
        # **This probably introduces extra unexpected `mvdelim` strings in the result.**
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   If `prepended_field` contains the `mvdelim` character, you probably want to set
        # rubocop:enable Layout/LineLength
        #   `multivalue_prepended_field: true`.
        #
        # Used in pipeline as:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # transform Prepend::FieldToFieldValue, target_field: :a, prepended_field: :b, sep: ': ',
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #                                        delete_prepended: true, mvdelim: ';',
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #                                        multivalue_prepended_field: true
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Results in:
        #
        # ```
        # | a              |
        # |----------------|
        # | d: c           |
        # | g: e;f         |
        # |                |
        # | i              |
        # | l: j;m: k      |
        # | r: o;s: p;q    |
        # | ;v: t          |
        # ```
        #
        # rubocop:todo Layout/LineLength
        # If there are more `target_field` values than `prepend_field` values after they are split,
        # rubocop:enable Layout/LineLength
        #   nothing is prepended to remaining `target_field` values.
        class FieldToFieldValue
          # rubocop:todo Layout/LineLength
          # Error raised if `FieldToFieldValue` is constructed with `mvdelim` blank and
          # rubocop:enable Layout/LineLength
          #   `multivalue_prepended_field` true
          class MissingDelimiterError < StandardError
            # rubocop:todo Layout/LineLength
            MSG = "You must provide an mvdelim string if multivalue_prepended_field is true"
            # rubocop:enable Layout/LineLength
            def initialize(msg = MSG)
              super
            end
          end

          # @param target_field [Symbol] Name of field to prepend to
          # rubocop:todo Layout/LineLength
          # @param prepended_field [Symbol] Name of field whose value should be prepended
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          # @param sep [String] Text inserted between prepended field value and target field value
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          # @param delete_prepended [Boolean] Whether or not to delete the prepended_field column
          # rubocop:enable Layout/LineLength
          #   after prepending
          # rubocop:todo Layout/LineLength
          # @param mvdelim [String] Character(s) on which to split multiple values in target field
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   before prepending. If empty string, behaves as a single value field
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          # @param multivalue_prepended_field [Boolean] Whether prepended field should be treated
          # rubocop:enable Layout/LineLength
          #   as multivalued
          # rubocop:todo Layout/LineLength
          # @raise [MissingDelimiterError] if constructed with multivalue_prepended_field true and
          # rubocop:enable Layout/LineLength
          #   no mvdelim value
          # rubocop:disable Metrics/ParameterLists
          # rubocop:todo Layout/LineLength
          def initialize(target_field:, prepended_field:, sep: "", delete_prepended: false, mvdelim: "",
            # rubocop:enable Layout/LineLength
            multivalue_prepended_field: false)
            @field = target_field
            @prepend = prepended_field
            @sep = sep
            @delete = delete_prepended
            @mvdelim = mvdelim
            @multival_prepend = multivalue_prepended_field
            raise MissingDelimiterError if @multival_prepend && @mvdelim.blank?
          end
          # rubocop:enable Metrics/ParameterLists

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            field_val = row.fetch(@field, nil)
            prepend_val = row.fetch(@prepend, nil)
            row.delete(@prepend) if @delete
            return row if field_val.blank? || prepend_val.blank?

            values = @mvdelim.blank? ? [field_val] : field_val.split(@mvdelim)

            if @multival_prepend
              row[@field] =
                mv_prepend(row, prepend_val, values)
            end
            return row if @multival_prepend

            row[@field] = sv_prepend(row, prepend_val, values)
            row
          end

          private

          def sv_prepend(_row, prepend_val, field_vals)
            field_vals.map { |val| prepended_val(prepend_val, val) }
              .join(@mvdelim)
          end

          def mv_prepend(_row, prepend_val, field_vals)
            prefixes = prepend_val.split(@mvdelim)
            field_vals.each_with_index.map { |val, i|
              prepended_val(prefixes[i], val)
            }
              .join(@mvdelim)
          end

          def prepended_val(prefix, val)
            return val if val.blank?
            return val if prefix.blank?

            "#{prefix}#{@sep}#{val}"
          end

          def get_prepended(val, i, prefixes)
            prefix = prefixes[i] || prefixes[-1]
            "#{prefix}#{@sep}#{val}"
          end
        end
      end
    end
  end
end
