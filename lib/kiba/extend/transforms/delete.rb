module Kiba
  module Extend
    module Transforms
      module Delete
        ::Delete = Kiba::Extend::Transforms::Delete
        class EmptyFieldValues
          def initialize(fields:, sep:)
            @fields = fields
            @sep = sep
          end

          def process(row)
            @fields.each do |field|
              val = row.fetch(field)
              unless val.nil?
                row[field] = val.split(@sep).compact.reject{ |e| e.empty? }.join(@sep)
              end
            end
            row
          end
        end
        
        class Fields
          def initialize(fields:)
            @fields = fields
          end

          def process(row)
            @fields.each{ |name| row.delete(name) }
            row
          end
        end

        class FieldsExcept
          def initialize(keepfields:)
            @fields = keepfields
          end

          def process(row)
            deletefields = row.keys - @fields
            deletefields.each{ |f| row.delete(f) }
            row
          end
        end

        class FieldValueContainingString
          def initialize(fields:, match:, casesensitive: true)
            @fields = fields
            @match = casesensitive ? match : match.downcase
            @casesensitive = casesensitive
          end

          def process(row)
            @fields.each do |field|
              exval = row.fetch(field)
              if exval.nil?
                # do nothing
              else
                exval = @casesensitive ? row.fetch(field) : row.fetch(field).downcase
                row[field] = nil if exval[@match]
              end
            end
            row
          end
        end

        class FieldValueIfEqualsOtherField
          def initialize(delete:, if_equal_to:, multival: false, sep: nil, grouped_fields: [], case_sensitive: true)
            @delete = delete
            @compare = if_equal_to
            @multival = multival
            @sep = sep
            @group = grouped_fields
            @case_sensitive = case_sensitive
          end

          def process(row)
            comparefield = @case_sensitive ? row.fetch(@compare) : row.fetch(@compare).downcase
            fv = row.fetch(@delete)
            unless fv.nil?
              fv = @multival ? fv.split(@sep) : [fv]
              fvcompare = @case_sensitive ? fv : fv.map{ |e| e.downcase}
              result = []
              deleted = []
              fvcompare.each_with_index do |val, i|
                if val == comparefield
                  result << nil
                  deleted << i
                else
                  result << fv[i]
                end
                row[@delete] = result.compact.join(@sep)
              end
              @group.each do |gf|
                gfval = row.fetch(gf)
                unless gfval.nil?
                  gfvals = gfval.split(@sep)
                  deleted.sort.reverse.each{ |i| gfvals.delete_at(i) }
                  row[gf] = gfvals.join(@sep)
                end
              end
            end
            row
          end
        end

        class FieldValueMatchingRegexp
          def initialize(fields:, match:, casesensitive: true)
            @fields = fields
            @match = casesensitive ? Regexp.new(match) : Regexp.new(match, Regexp::IGNORECASE)
          end

          def process(row)
            @fields.each do |field|
              exval = row.fetch(field)
              if exval.nil?
                #do nothing
              else
                row[field] = nil if exval.match?(@match)
              end
            end
            row
          end
        end
      end
    end
  end
end
