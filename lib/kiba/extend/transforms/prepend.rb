module Kiba
  module Extend
    module Transforms
      module Prepend
        ::Prepend = Kiba::Extend::Transforms::Prepend

        # Adds the value of prepended_field to the beginning of the value(s) of the target_field
        #
        # If target field value is blank, it is left blank, even if there is a prepended field value. If there is no value in prepended field, target field is left as-is
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
        #  transform Prepend::FieldToFieldValue, target_field: :a, prepended_field: :b, sep: ': '
        #
        # Results in:
        #
        #  | a      | b |
        #  --------------
        #  | d: c   | d |
        #  | d: e;f | g |
        #  |        | h |
        #  | i      |   |
        #
        # Used in pipeline as: 
        #  transform Prepend::FieldToFieldValue, target_field: :a, prepended_field: :b, sep: ': ',
        #                                        delete_prepended: true, mvdelim: ';'
        #
        # Results in:
        #
        #  | a         |
        #  -------------
        #  | d: c      |
        #  | d: e;d: f |
        #  |           |
        #  | i         |
        class FieldToFieldValue
          # @param target_field [Symbol] Name of field to prepend to
          # @param prepended_field [Symbol] Name of field whose value should be prepended
          # @param sep [String] Text inserted between prepended field value and target field value
          # @param delete_prepended [Boolean] Whether or not to delete the prepended_field column after prepending
          # @param mvdelim [String] Character(s) on which to split multiple values in target field before prepending. If empty string, behaves as a single value field
          def initialize(target_field:, prepended_field:, sep: '', delete_prepended: false, mvdelim: '')
            @field = target_field
            @prepend = prepended_field
            @sep = sep
            @delete = delete_prepended
            @mvdelim = mvdelim
          end

          # @private
          def process(row)
            fv = row.fetch(@field, nil)
            prepend_val = row.fetch(@prepend, nil)
            row.delete(@prepend) if @delete
            return row if fv.blank?
            return row if prepend_val.blank?

            values = @mvdelim.blank? ? [fv] : fv.split(@mvdelim)
            row[@field] = values.map{ |val| "#{prepend_val}#{@sep}#{val}"}
              .join(@mvdelim)
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
