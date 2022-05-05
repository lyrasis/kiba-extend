# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Cspace
        class NormalizeForID
          def initialize(source:, target:, multival: false, delim: nil)
            @source = source
            @target = target
            @multival = multival
            @delim = delim
          end

          # @private
          def process(row)
            row[@target] = nil
            val = row.fetch(@source, nil)
            return row if val.blank?

            row[@target] = values(val).map{ |val| normalize(val) }.join(@delim)
            row
          end

          private

          def normalize(val)
            val = val.unicode_normalized?(:nfkc) ? val : val.unicode_normalize(:nfkc)
            BRUTEFORCE.each { |k, v| val = val.gsub(k, v) }
            ActiveSupport::Inflector.transliterate(val).gsub(/\W/, '').downcase
          end
          
          def values(val)
            return [val] unless @multival

            val.split(@delim)
          end
        end
      end
    end
  end
end
