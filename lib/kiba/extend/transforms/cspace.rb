module Kiba
  module Extend
    module Transforms
      # Transformations specific to preparing data for import into CollectionSpace
      module Cspace
        ::Cspace = Kiba::Extend::Transforms::Cspace
        # Characters or character combinations known to be treated strangely by CollectionSpace when creating IDs. Used as a lookup to force the substitution we need
        BRUTEFORCE = {
          'ș' => 's',
          't̕a' => 'ta'
        }

        class ConvertToID
          def initialize(source:, target:)
            @source = source
            @target = target
          end

          # @private
          def process(row)
            val = row.fetch(@source, '')
            idval = val.gsub(/\W/, '')
            row[@target] = "#{idval}#{XXhash.xxh32(idval)}"
            row
          end
        end

        class FlagInvalidCharacters
          def initialize(check:, flag:)
            @check = check
            @flag = flag
          end

          # @private
          def process(row)
            val = row.fetch(@check, nil)
            if val.blank?
              row[@flag] = nil
            else
              val = val.unicode_normalized?(:nfkc) ? val : val.unicode_normalize(:nfkc)
              BRUTEFORCE.each{ |k, v| val = val.gsub(k, v) }
              norm = ActiveSupport::Inflector.transliterate(val, '%INVCHAR%')
              row[@flag] = norm.include?('%INVCHAR%') ? norm : nil
            end
            row
          end
        end
        
        class NormalizeForID
          def initialize(source:, target:)
            @source = source
            @target = target
          end
          
          # @private
          def process(row)
            val = row.fetch(@source, nil)
            if val.blank?
              row[@target] = nil
            else
              val = val.unicode_normalized?(:nfkc) ? val : val.unicode_normalize(:nfkc)
              BRUTEFORCE.each{ |k, v| val = val.gsub(k, v) }
              norm = ActiveSupport::Inflector.transliterate(val)
              norm = norm.gsub(/\W/, '')
              row[@target] = norm.downcase
            end
            row
          end
        end
      end
    end
  end
end
