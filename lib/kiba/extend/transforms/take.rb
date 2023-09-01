# frozen_string_literal: true

# rubocop:todo Layout/LineLength

module Kiba
  module Extend
    module Transforms
      # Takes values from fields/rows
      module Take
        ::Take = Kiba::Extend::Transforms::Take

        # Take the first value from given fields and put then in the given target fields.
        #
        # If no target fields are given, values in the original fields will be replaced with first values.
        #
        # If `nil` or `` are passed in as targets, the original field(s) corresponding to those targets
        #   will be replaced by their first values, while other targets will be created as new fields.
        #
        # The "first value" of a nil field is nil. The "first value" of an empty string field is an
        #   empty string.
        #
        # # Examples
        #
        # Input table:
        #
        # ```
        # | a   | b   |
        # |-----------|
        # | c|d | e|j |
        # |     | nil |
        # | |f  | g|  |
        # | h   | i   |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Take::First, fields: %i[a b], targets: %i[y z], delim: '|'
        # ```
        #
        # Results in:
        #
        # ```
        # | a   | b   | y | z   |
        # |---------------------|
        # | c|d | e|j | c | e   |
        # |     | nil |   | nil |
        # | |f  | g|  |   | g   |
        # | h   | i   | h | i   |
        # ```

        class First
          def initialize(fields:, delim:, targets: [])
            @fields = [fields].flatten
            @targets = targets
            @delim = delim
            build_targets
            @field_map = @fields.zip(@targets).to_h
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            @field_map.each do |field, target|
              field_val = row.fetch(field, nil)
              row[target] = first_val(field_val)
            end
            row
          end

          private

          # ensures targets has the same number of elements as fields
          def build_targets
            if @targets.empty?
              @targets = @fields
              return
            end

            until equal_length?
              @targets << @fields[index]
            end

            @targets.each_with_index do |target, i|
              next unless target.blank?

              @targets[i] = @fields[i]
            end
          end

          def equal_length?
            fields_len == targets_len
          end

          def index
            fields_len - targets_len
          end

          def fields_len
            @fields.length
          end

          def first_val(val)
            return val if val.blank?

            val.split(@delim).first.strip
          end

          def targets_len
            @targets.length
          end
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
