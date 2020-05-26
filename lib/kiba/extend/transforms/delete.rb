module Kiba
  module Extend
    module Transforms
      module Delete
        ::Delete = Kiba::Extend::Transforms::Delete
        class Fields
          def initialize(fields:)
            @fields = fields
          end

          def process(row)
            @fields.each{ |name| row.delete(name) }
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
          def initialize(delete:, if_equal_to:)
            @delete = delete
            @compare = if_equal_to
          end

          def process(row)
            row[@delete] = nil if row.fetch(@delete) == row.fetch(@compare)
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
