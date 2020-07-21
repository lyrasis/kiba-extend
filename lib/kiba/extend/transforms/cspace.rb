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

        class NormalizeForID
          def initialize(source:, target:)
            @source = source
            @target = target
          end

          def process(row)
            val = row.fetch(@source, nil)
            if val.nil? || val.empty?
              row[@target] = nil
            else
              norm = ActiveSupport::Inflector.transliterate(val)
              norm = norm.gsub(/\W/, '')
              row[@target] = norm
            end
            row
          end
        end
      end
    end
  end
end
