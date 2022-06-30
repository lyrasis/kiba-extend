# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Cspace
        # @abstract Use to subclass project-specific transformers. Implementation should define a class
        #   with `:initialize` that defines `@sources` and `@targets` (both: [Array<Symbol>]). `@sources`
        #   is the list of original source fields that field group intermediate fields were derived from (with
        #   `source_targetfield` pattern). `@targets` is list of final field group fields that the
        #   intermediate fields will be combined into.
        #
        # See https://github.com/lyrasis/kiba-tms/blob/main/lib/kiba/tms/transforms/objects/annotation_combiner.rb
        #   for an example of a concrete subclass of this class.
        class AbstractFieldGroupCombiner
          def process(row)
            targets.each do |target|
              row[target] = combined(row, target)
              temp_fields(target).each{ |field| row.delete(field) }
            end
            row
          end

          private

          attr_reader :sources, :targets

          def combined(row, target)
            values(row, target).join(Tms.delim)
          end

          def temp_fields(target)
            sources.map{ |source| "#{source}_#{target}".to_sym } 
          end

          def values(row, target)
            temp_fields(target).map{ |field| row[field] }.reject{ |val| val.blank? }
          end
        end
      end
    end
  end
end
