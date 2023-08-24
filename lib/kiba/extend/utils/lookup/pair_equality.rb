# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      module Lookup
        class PairEquality
          attr_reader :result

          def initialize(pair:, row:, mergerow: {})
            comparison_type = :equals
            pair = pair.map { |e| e.split("::") }
            # convert row or mergerow fieldnames to symbols
            pair = pair.each { |arr| arr[1] = arr[1].to_sym if arr[0]["row"] }
            # fetch or convert values for comparison
            pair = pair.map do |arr|
              case arr[0]
              when "row"
                row.fetch(arr[1], "%field does not exist%")
              when "mergerow"
                mergerow.fetch(arr[1], "%field does not exist%")
              when "revalue"
                comparison_type = :match
                arr[1] = "^#{arr[1]}$"
                Regexp.new(arr[1])
              when "value"
                arr[1]
              end
            end

            unless pair.include?(nil) && pair.include?("")
              # replace nil value with empty string for comparison
              pair = pair.map { |e| e = e.nil? ? "" : e }
            end

            case comparison_type
            when :equals
              @result = pair[0] == pair[1]
            when :match
              @result = pair[0].match?(pair[1])
            end
          end
        end
      end
    end
  end
end
