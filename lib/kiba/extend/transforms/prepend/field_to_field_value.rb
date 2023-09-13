# frozen_string_literal: true

# rubocop:todo Layout/LineLength

module Kiba
  module Extend
    module Transforms
      module Prepend
        # Adds the value of `prepended_field` to the beginning of the value(s) of the `target_field`
        #
        # If target field value is blank, it is left blank, even if there is a prepended field value.
        #   If there is no value in prepended field, target field is left as-is
        #
        # # Examples
        #
        # Used in pipeline as:
        #
        # ~~~
        # transform Prepend::FieldToFieldValue, target_field: :a, prepended_field: :b, sep: ': '
        # ~~~
        #
        # Input table:
        #
        # ~~~
        # | a     | b   |
        # |-------+-----|
        # | c     | d   |
        # | e;f   | g   |
        # |       | h   |
        # | i     |     |
        # | j;k   | l;m |
        # | o;p;q | r;s |
        # | ;t    | u;v
        # ~~~
        #
        # Results in:
        #
        # ~~~
        # | a          | b   |
        # |------------|-----|
        # | d: c       | d   |
        # | g: e;f     | g   |
        # |            | h   |
        # | i          |     |
        # | l;m: j;k   | l;m |
        # | r;s: o;p;q | r;s |
        # | u;v: ;t    | u;v |
        # ~~~
        #
        # Used in pipeline as:
        #
        # ~~~
        # transform Prepend::FieldToFieldValue, target_field: :a, prepended_field: :b, sep: ': ',
        #                                        delete_prepended: true, mvdelim: ';'
        # ~~~
        #
        # Input table:
        #
        # ~~~
        # | a     | b   |
        # |-------+-----|
        # | c     | d   |
        # | e;f   | g   |
        # |       | h   |
        # | i     |     |
        # | j;k   | l;m |
        # | o;p;q | r;s |
        # | ;t    | u;v
        # ~~~
        #
        # Results in:
        #
        # ~~~
        # | a                    |
        # |----------------------|
        # | d: c                 |
        # | g: e;g: f            |
        # |                      |
        # | i                    |
        # | l;m: j;l;m: k        |
        # | r;s: o;r;s: p;r;s: q |
        # | ;u;v: t              |
        # ~~~
        #
        # **This probably introduces extra unexpected `mvdelim` strings in the result.**
        #   If `prepended_field` contains the `mvdelim` character, you probably want to set
        #   `multivalue_prepended_field: true`.
        #
        # Used in pipeline as:
        #
        # ~~~
        # transform Prepend::FieldToFieldValue, target_field: :a, prepended_field: :b, sep: ': ',
        #                                        delete_prepended: true, mvdelim: ';',
        #                                        multivalue_prepended_field: true
        # ~~~
        #
        # Results in:
        #
        # ~~~
        # | a              |
        # |----------------|
        # | d: c           |
        # | g: e;f         |
        # |                |
        # | i              |
        # | l: j;m: k      |
        # | r: o;s: p;q    |
        # | ;v: t          |
        # ~~~
        #
        # If there are more `target_field` values than `prepend_field` values after they are split,
        #   nothing is prepended to remaining `target_field` values.
        class FieldToFieldValue
          # Error raised if `FieldToFieldValue` is constructed with `mvdelim` blank and
          #   `multivalue_prepended_field` true
          class MissingDelimiterError < StandardError
            MSG = "You must provide an mvdelim string if multivalue_prepended_field is true"
            def initialize(msg = MSG)
              super
            end
          end

          # @param target_field [Symbol] Name of field to prepend to
          # @param prepended_field [Symbol] Name of field whose value should be prepended
          # @param sep [String] Text inserted between prepended field value and target field value
          # @param delete_prepended [Boolean] Whether or not to delete the prepended_field column
          #   after prepending
          # @param mvdelim [String] Character(s) on which to split multiple values in target field
          #   before prepending. If empty string, behaves as a single value field
          # @param multivalue_prepended_field [Boolean] Whether prepended field should be treated
          #   as multivalued
          # @raise [MissingDelimiterError] if constructed with multivalue_prepended_field true and
          #   no mvdelim value
          def initialize(target_field:, prepended_field:, sep: "", delete_prepended: false, mvdelim: "",
            multivalue_prepended_field: false)
            @field = target_field
            @prepend = prepended_field
            @sep = sep
            @delete = delete_prepended
            @mvdelim = mvdelim
            @multival_prepend = multivalue_prepended_field
            raise MissingDelimiterError if @multival_prepend && @mvdelim.blank?
          end

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
            field_vals.each_with_index.map do |val, i|
              prepended_val(prefixes[i], val)
            end
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
# rubocop:enable Layout/LineLength
