# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Cspace
        class FlagInvalidCharacters
          def initialize(check:, flag:)
            @check = check
            @flag = flag
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            val = row.fetch(@check, nil)
            if val.blank?
              row[@flag] = nil
            else
              val = val.unicode_normalized?(:nfkc) ? val : val.unicode_normalize(:nfkc)
              Cspace.shady_characters.each { |k, v| val = val.gsub(k, v) }
              norm = ActiveSupport::Inflector.transliterate(val, '%INVCHAR%')
              row[@flag] = norm.include?('%INVCHAR%') ? norm : nil
            end
            row
          end
        end
      end
    end
  end
end
