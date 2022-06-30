# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Cspace
        # @note This transform is **NOT** meant to be used directly
        # @abstract Subclass in individual projects by defining initializer for subclass specifying `@source`
        #   and `@type` values
        # Provides a base class to inherit from in order to simply map a field to annotation field group in
        #   CollectionSpace Object record. Body of source field becomes `:source_annotationnote`. The `@type`
        #   value becomes `:source_annotationtype`.
        #
        # Note that you will still need to use {{Kiba::Extend::Transforms::CombineValues::FromFieldsWithDelimiter}}
        #   to combine annotations from multiple source fields into final annotation field group fields for
        #   import.
        #
        # See https://github.com/lyrasis/kiba-tms/blob/main/lib/kiba/tms/transforms/objects/creditline.rb for an
        #   example of a concrete subclass of this class.
        class AbstractAnnotation
          # @private
          def process(row)
            val = row[source]
            if val.blank?
              row[type_target] = nil
              row[note_target] = nil
            else
              row[type_target] = type
              row[note_target] = val
            end
            row.delete(source)

            row
          end

          private

          attr_reader :source, :type

          def note_target
            @note_target ||= "#{source}_annotationnote".to_sym
          end

          def type_target
            @type_target ||= "#{source}_annotationtype".to_sym
          end
        end
      end
    end
  end
end
