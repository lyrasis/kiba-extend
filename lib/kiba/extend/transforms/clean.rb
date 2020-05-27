module Kiba
  module Extend
    module Transforms
      module Clean
        ::Clean = Kiba::Extend::Transforms::Clean
        class DelimiterOnlyFields
          def initialize(delim:)
            @delim = delim
          end

          def process(row)
            row.each do |hdr, val|
              row[hdr] = nil if delim_only?(val)
            end
            row
          end

          private

          def delim_only?(val)
            chk = val.gsub(@delim, '').strip
            chk.empty? ? true : false
          end
        end

        class DowncaseFieldValues
          def initialize(fields:)
            @fields = fields
          end

          def process(row)
            @fields.each do |field|
              val = row.fetch(field)
              row[field] = val.is_a?(String) ? val.downcase : val
            end
            row
          end
        end
        
        class RegexpFindReplaceFieldVals
          def initialize(fields:, find:, replace:, casesensitive: true, debug: false)
            @fields = fields
            @find = Regexp.new(find) if casesensitive == true
            @find = Regexp.new(find, Regexp::IGNORECASE) if casesensitive == false
            @replace = replace
            @debug = debug
          end

          def process(row)
            @fields.each do |field|
            oldval = row.fetch(field)
            unless oldval.nil?
              newval = oldval.gsub(@find, @replace)
              target = @debug ? "#{field}_repl".to_sym : field
              row[target] = newval.empty? ? nil : newval
            end
            end
            row
          end
        end
      end
    end
  end
end
