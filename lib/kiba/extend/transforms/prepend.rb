module Kiba
  module Extend
    module Transforms
      # Transformations that add data to the beginning of a field
      module Prepend
        ::Prepend = Kiba::Extend::Transforms::Prepend

        # Adds the value of prepended_field to the beginning of the value(s) of the target_field
        #
        # If target field value is blank, it is left blank, even if there is a prepended field value. If there is no value in prepended field, target field is left as-is
        #
        # # Examples
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
        # ```
        # 
        # Used in pipeline as:
        #
        # ```
        # transform Prepend::FieldToFieldValue, target_field: :a, prepended_field: :b, sep: ': '
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
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Prepend::FieldToFieldValue, target_field: :a, prepended_field: :b, sep: ': ',
        #                                        delete_prepended: true, mvdelim: ';'
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
        # ```
        #
        # **This probably introduces extra unexpected `mvdelim` strings in the result.** If `prepended_field` contains the `mvdelim` character, you probably want to set `multivalue_prepended_field: true`. 
        #
        # Used in pipeline as:
        #
        # ```
        # transform Prepend::FieldToFieldValue, target_field: :a, prepended_field: :b, sep: ': ',
        #                                        delete_prepended: true, mvdelim: ';',
        #                                        multivalue_prepended_field: true
        # ```
        #
        # Results in:
        #
        # ```
        # | a              |
        # |----------------|
        # | d: c           |
        # | g: e;g: f      |
        # |                |
        # | i              |
        # | l: j;m: k      |
        # | r: o;s: p;s: q |
        # ```
        #
        # If there are more `target_field` values than `prepend_field` values after they are split, the final `prepend_field` value is prepended to remaining `target_field` values.
        class FieldToFieldValue
          # @param target_field [Symbol] Name of field to prepend to
          # @param prepended_field [Symbol] Name of field whose value should be prepended
          # @param sep [String] Text inserted between prepended field value and target field value
          # @param delete_prepended [Boolean] Whether or not to delete the prepended_field column after prepending
          # @param mvdelim [String] Character(s) on which to split multiple values in target field before prepending. If empty string, behaves as a single value field
          # @param multivalue_prepended_field [Boolean] Whether prepended field should be treated as multivalued
          def initialize(target_field:, prepended_field:, sep: '', delete_prepended: false, mvdelim: '',
                         multivalue_prepended_field: false)
            @field = target_field
            @prepend = prepended_field
            @sep = sep
            @delete = delete_prepended
            @mvdelim = mvdelim
            @multival_prepend = multivalue_prepended_field
          end

          # @private
          def process(row)
            fv = row.fetch(@field, nil)
            prepend_val = row.fetch(@prepend, nil)
            row.delete(@prepend) if @delete
            return row if fv.blank?
            return row if prepend_val.blank?

            values = @mvdelim.blank? ? [fv] : fv.split(@mvdelim)
            if @multival_prepend
              result = []
              prefixes = @mvdelim.blank? ? [prepend_val] : prepend_val.split(@mvdelim)
              values.each_with_index do |val, i|
                prefix = prefixes[i] ? prefixes[i] : prefixes[-1]
                result << "#{prefix}#{@sep}#{val}"
              end
              row[@field] = result.join(@mvdelim)
            else
              row[@field] = values.map{ |val| "#{prepend_val}#{@sep}#{val}"}
                .join(@mvdelim)
            end
            
            row.delete(@prepend) if @delete
            row
          end
        end

        # Adds the specified value to the specified field
        #
        # If target field value is blank, it is left blank
        #
        # == Examples
        # Input table:
        #
        #  | a   | b |
        #  -----------
        #  | c   | d |
        #  | e;f | g |
        #  |     | h |
        #  | i   |   |
        #
        # Used in pipeline as: 
        #  transform Prepend::ToFieldValue, field: :a, value: 'pre: '
        #
        # Results in:
        #
        #  | a        | b |
        #  --------------
        #  | pre: c   | d |
        #  | pre: e;f | g |
        #  |          | h |
        #  | pre: i   |   |
        #
        # Used in pipeline as: 
        #  transform Prepend::ToFieldValue, field: :a, value: 'pre: ', mvdelim: ';'
        #
        # Results in:
        #
        #  | a             | b |
        #  ---------------------
        #  | pre: c        | d |
        #  | pre: e;pre: f | g |
        #  |               | h |
        #  | pre: i        |   |
        class ToFieldValue
          # @param field [Symbol] The field to prepend to
          # @param value [String] The value to be prepended
          # @param mvdelim [String] Character(s) on which to split multiple values in field before prepending. If empty string, behaves as a single value field
          def initialize(field:, value:, mvdelim: '')
            @field = field
            @value = value
            @mvdelim = mvdelim
          end

          # @private
          def process(row)
            fv = row.fetch(@field, nil)
            return row if fv.blank?

            fieldvals = @mvdelim.blank? ? [fv] : fv.split(@mvdelim)
            row[@field] = fieldvals.map{ |fv| "#{@value}#{fv}" }.join(@mvdelim)
            row
          end
        end
      end
    end
  end
end
