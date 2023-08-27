# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Helpers
        # @since 2.9.0
        #
        # Service object to return whether given values are "delimiter only".
        #
        # rubocop:todo Layout/LineLength
        # **NOTE:** By default, "delimiter only" is `true` if a value is `nil` or `empty?`. It is also true
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   if the value consists of only the given `delim` and, optionally, any spaces. If given one or more
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   `treat_as_null` values, it is true if the value consists of those "null" strings, the given
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   delimiter, and spaces only. If you specify `blank_result: false`, then values that are `nil` or
        # rubocop:enable Layout/LineLength
        #   `empty?` will not count as "delimiter only"
        class DelimOnlyChecker
          class << self
            def call(delim:, value:, treat_as_null:, blank_result:)
              new(delim: delim, treat_as_null: treat_as_null,
                blank_result: blank_result).call(value)
            end
          end

          # @param delim [String]
          # rubocop:todo Layout/LineLength
          # @param treat_as_null [nil, String, Array(String)] value(s) to treat as though they are null
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          # @param blank_result [Boolean] what to return for values that are `nil?` or `empty?`
          # rubocop:enable Layout/LineLength
          def initialize(delim: Kiba::Extend.delim, treat_as_null: nil,
            blank_result: true)
            @delim = delim
            # rubocop:todo Layout/LineLength
            @nullvals = treat_as_null.nil? ? nil : [treat_as_null].flatten.sort_by do |val|
                                                     # rubocop:enable Layout/LineLength
                                                     val.length
                                                   end.reverse
            @blank_result = blank_result
          end

          # @param value [String]
          # @return [true] if `value` is delimiter-only, **nil, or empty**
          # @return [false] otherwise
          def call(value)
            return blank_result if value.nil?

            no_nulls = nullvals ? remove_nulls(value) : value.strip
            return blank_result if no_nulls.empty?

            no_delims = no_nulls.gsub(delim, "").strip
            no_delims.empty?
          end

          private

          attr_reader :delim, :nullvals, :blank_result

          def remove_nulls(value)
            str = value.dup
            nullvals.each { |nv| str = str.gsub(nv, "") }
            str.strip
          end
        end
      end
    end
  end
end
