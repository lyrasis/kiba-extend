# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Copy
        # Copy the value of a field to another field. If `to` field does not yet exist, it is created. Otherwise, it is overwritten with the copied value.
        # @todo Add `safe_copy` parameter that will prevent overwrite of existing data in `to`
        class Field
          class MissingFromFieldError < Kiba::Extend::Error
            def initialize(from)
              msg = "Cannot copy from nonexistent field `#{from}`"
              super(msg)
            end
          end
          
          # @param from [Symbol] Name of field to copy data from
          # @param to [Symbol] Name of field to copy data to
          def initialize(from:, to:)
            @from = from
            @to = to
          end

          # @private
          def process(row)
            raise MissingFromFieldError.new(from) unless row.key?(from)
            
            row[to] = row.fetch(from)
            row
          end

          private

          attr_reader :from, :to
        end
      end
    end
  end
end
