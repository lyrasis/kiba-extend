# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Helpers
        # @since 2.9.0
        #
        # Service object to return whether given values are "delimiter only".
        #
        # **NOTE:** By default, "delimiter only" is `true` if a value is `nil` or `empty?`. It is also true
        #   if the value consists of only the given `delim` and, optionally, any spaces. If given one or more
        #   `treat_as_null` values, it is true if the value consists of those "null" strings, the given
        #   delimiter, and spaces only. If you specify `blank_result: false`, then values that are `nil` or
        #   `empty?` will not count as "delimiter only"
        class DelimOnlyChecker
          class << self
            def call(delim:, value:, treat_as_null:, blank_result:)
              self.new(delim: delim, treat_as_null: treat_as_null, blank_result: blank_result).call(value)
            end
          end
          
          # @param delim [String]
          # @param treat_as_null [nil, String, Array(String)] value(s) to treat as though they are null
          # @param blank_result [Boolean] what to return for values that are `nil?` or `empty?`
          def initialize(delim: Kiba::Extend.delim, treat_as_null: nil, blank_result: true)
            @delim = delim
            @nullvals = treat_as_null.nil? ? nil : [treat_as_null].flatten.sort_by{ |val| val.length }.reverse
            @blank_result = blank_result
          end

          # @param value [String]
          # @return [true] if `value` is delimiter-only, **nil, or empty**
          # @return [false] otherwise
          def call(value)
            return blank_result if value.nil?
            
            no_nulls = nullvals ? remove_nulls(value) : value.strip
            return blank_result if no_nulls.empty?

            no_delims = no_nulls.gsub(delim, '').strip
            no_delims.empty?
          end
          
          private

          attr_reader :delim, :nullvals, :blank_result

          def remove_nulls(value)
            str = value.dup
            nullvals.each{ |nv| str = str.gsub(nv, '') }
            str.strip
          end
        end
      end
    end
  end
end
