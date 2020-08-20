module Kiba
  module Extend
    module Transforms
      module Clean
        ::Clean = Kiba::Extend::Transforms::Clean

        module Helpers
          ::Clean::Helpers = Kiba::Extend::Transforms::Clean::Helpers
          def delim_only?(val, delim)
            chk = val.gsub(delim, '').strip
            chk.empty? ? true : false
          end
        end

        
        class AlphabetizeFieldValues
          include Clean::Helpers
          def initialize(fields:, delim:)
            @fields = fields
            @delim = delim
          end

          def process(row)
            @fields.each do |field|
              vals = row.fetch(field, nil)
              next if vals.blank?
              next if delim_only?(vals, @delim)
              vals = vals.split(@delim)
              next if vals.size == 1
              row[field] = vals.sort_by(&:downcase).join(@delim)
            end
            row
          end
        end

        class ClearFields
          def initialize(fields:)
            @fields = fields
          end

          def process(row)
            @fields.each{ |field| row[field] = nil }
            row
          end
        end
        
        class DelimiterOnlyFields
          include Clean::Helpers
          def initialize(delim:)
            @delim = delim
          end

          def process(row)
            row.each do |hdr, val|
              row[hdr] = nil if val.is_a?(String) && delim_only?(val, @delim)
            end
            row
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

        class EmptyFieldGroups
          def initialize(groups:, sep:)
            @groups = groups
            @sep = sep
          end

          def process(row)
            @groups.each{ |group| process_group(row, group) }
            row
          end

          private

          def process_group(row, group)
            thisgroup = group.map{ |field| row.fetch(field, '')}
              .map{ |val| val.nil? ? [] : " #{val} ".split(@sep) }
              .map{ |arr| arr.map{ |e| e.strip } }

            cts = thisgroup.map{ |arr| arr.size }.uniq
            to_delete = []

            if cts.size > 1
              # do nothing - different numbers of elements, not safe to edit
            elsif cts.size == 0
              # do nothing - all fields already blank
            else
              thisgroup.first.each_with_index{ |element, i| to_delete << i if all_empty?(thisgroup, i) }
              to_delete.sort.reverse.each do |i|
                thisgroup.each{ |arr| arr.delete_at(i) }
              end
              thisgroup.each_with_index{ |arr, i| row[group[i]] = arr.empty? ? nil : arr.join(@sep) }
            end
          end

          def all_empty?(group, index)
            thesevals = group.map{ |arr| arr[index] }
              .map{ |val| val.empty? ? nil : val }
              .uniq
              .compact
            thesevals.empty? ? true : false
          end
        end
        
        class RegexpFindReplaceFieldVals
          def initialize(fields:, find:, replace:, casesensitive: true, multival: false, sep: nil, debug: false)
            @fields = fields
            @find = Regexp.new(find) if casesensitive == true
            @find = Regexp.new(find, Regexp::IGNORECASE) if casesensitive == false
            @replace = replace
            @debug = debug
            @mv = multival
            @sep = sep
          end

          def process(row)
            @fields.each do |field|
              oldval = row.fetch(field)
              if oldval.nil?
                newval = nil
              else
                newval = @mv ? mv_find_replace(oldval) : sv_find_replace(oldval)
              end
              target = @debug ? "#{field}_repl".to_sym : field
              row[target] = newval.nil? ? nil : newval.empty? ? nil : newval
            end
            row
          end

          private

          def mv_find_replace(val)
            val.split(@sep).map{ |v| v.gsub(@find, @replace) }.join(@sep)
          end

          def sv_find_replace(val)
            val.gsub(@find, @replace)
          end
        end

        class StripFields
          def initialize(fields:)
            @fields = fields
          end

          def process(row)
            @fields.each do |field|
              val = row.fetch(field, nil)
              if val.nil? || val.empty?
                row[field] = nil
              else
                row[field] = val.strip
              end
            end
            row
          end
        end
      end
    end
  end
end
