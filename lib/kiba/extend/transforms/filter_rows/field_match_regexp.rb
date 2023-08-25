# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module FilterRows
        # rubocop:todo Layout/LineLength
        # Keep or reject rows where the value of the specified field matches the given regular expression.
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   Matches across the entire field value. I.e. a multivalued field is not split into segments which
        # rubocop:enable Layout/LineLength
        #   are each tested for a match.
        #
        # ## Examples
        #
        # Source data:
        #
        # ```
        # {val: 'N'},
        # {val: 'n'},
        # {val: 'NN'},
        # {val: 'NY'},
        # {val: ''},
        # {val: nil}
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # transform FilterRows::FieldMatchRegexp, action: :keep, field: :val, match: '^N'
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Resulting data:
        #
        # ```
        # {val: 'N'},
        # {val: 'NN'},
        # {val: 'NY'},
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # transform FilterRows::FieldMatchRegexp, action: :keep, field: :val, match: '^N', ignore_case: true
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Resulting data:
        #
        # ```
        # {val: 'N'},
        # {val: 'n'},
        # {val: 'NN'},
        # {val: 'NY'},
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # transform FilterRows::FieldMatchRegexp, action: :reject, field: :val, match: '^N'
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Resulting data:
        #
        # ```
        # {val: 'n'},
        # {val: ''},
        # {val: nil},
        # ```
        class FieldMatchRegexp
          include ActionArgumentable

          # @param action [:keep, :reject] what to do with row matching criteria
          # @param field [Symbol] to match value in
          # rubocop:todo Layout/LineLength
          # @param match [String] value that will be turned into a `Regexp` using `Regexp.new(match)`
          # rubocop:enable Layout/LineLength
          # @param ignore_case [Boolean] controls case sensitivity of matching
          def initialize(action:, field:, match:, ignore_case: false)
            validate_action_argument(action)
            @action = action
            @field = field
            @match = ignore_case ? Regexp.new(match,
              Regexp::IGNORECASE) : Regexp.new(match)
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            val = row.fetch(field)
            test = val ? val.match?(match) : false
            case action
            when :keep
              test ? row : nil
            when :reject
              test ? nil : row
            end
          end

          private

          attr_reader :action, :field, :match
        end
      end
    end
  end
end
