module Kiba
  module Extend
    module Transforms
      module Cspace
        ::Cspace = Kiba::Extend::Transforms::Cspace
        class ConvertToID
          def initialize(source:, target:)
            @source = source
            @target = target
          end

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

          def process(row)
            val = row.fetch(@check, nil)
            if val.blank?
              row[@flag] = nil
            else
              nval = val.encode('ASCII', 'binary', invalid: :replace,
                                undef: :replace, replace: 'INVALIDCHAR')
              row[@flag] = nval.include?('INVALIDCHAR') ? nval : nil
            end
            row
          end
        end
        
        class NormalizeForID
          def initialize(source:, target:)
            @source = source
            @target = target
          end

          def process(row)
            val = row.fetch(@source, nil)
            if val.blank?
              row[@target] = nil
            else
              brute_force = {
                'ș' => 's'
              }
              val = val.unicode_normalized?(:nfkc) ? val : val.unicode_normalize(:nfkc)
              brute_force.each{ |k, v| val = val.gsub(k, v) }
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
