# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Cspace
        class NormalizeForID
          include MultivalPlusDelimDeprecatable

          # @param source [Symbol] field whose value will be normalized
          # @param target [Symbol] field to populate with normalized value
          # @param multival [Boolean] **DEPRECATED - Do not use**
          # @param delim [nil, String] if given triggers treatment as
          #   multivalued, and is used to split/join string values
          def initialize(source:, target:, multival: omitted = true, delim: nil)
            @source = source
            @target = target
            @multival = set_multival(multival, omitted, self)
            @delim = delim
            @normalizer = Kiba::Extend::Utils::StringNormalizer.new(
              mode: :cspaceid
            )
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            row[target] = nil
            val = row.fetch(source, nil)
            return row if val.blank?

            row[target] = values(val).map{ |val| normalize(val) }.join(delim)
            row
          end

          private

          attr_reader :source, :target, :delim, :normalizer

          def normalize(val)
            normalizer.call(val)
          end

          def values(val)
            return [val] unless delim

            val.split(delim)
          end
        end
      end
    end
  end
end
