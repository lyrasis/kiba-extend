# frozen_string_literal: true

# rubocop:todo Layout/LineLength

module Kiba
  module Extend
    module Transforms
      module FilterRows
        # Keep or reject rows where the value of the specified field matches the given regular expression.
        #   Matches across the entire field value. I.e. a multivalued field is not split into segments which
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
        # transform FilterRows::FieldMatchRegexp, action: :keep, field: :val, match: '^N'
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
        # transform FilterRows::FieldMatchRegexp, action: :keep, field: :val, match: '^N', ignore_case: true
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
        # transform FilterRows::FieldMatchRegexp, action: :reject, field: :val, match: '^N'
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
          # @param match [String] value that will be turned into a `Regexp` using `Regexp.new(match)`
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
# rubocop:enable Layout/LineLength
