# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Copy
        # rubocop:todo Layout/LineLength
        # Copy the value of a field to another field. If `to` field does not yet exist, it is created. Otherwise, it is overwritten with the copied value.
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # @todo Add `safe_copy` parameter that will prevent overwrite of existing data in `to`
        # rubocop:enable Layout/LineLength
        class Field
          class MissingFromFieldError < Kiba::Extend::Error
            def initialize(from, fields)
              # rubocop:todo Layout/LineLength
              msg = "Cannot copy from nonexistent field `#{from}`\nExisting fields: #{fields.join(", ")}"
              # rubocop:enable Layout/LineLength
              super(msg)
            end
          end

          # @param from [Symbol] Name of field to copy data from
          # @param to [Symbol] Name of field to copy data to
          def initialize(from:, to:)
            @from = from
            @to = to
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            fail MissingFromFieldError.new(from, row.keys) unless row.key?(from)

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
