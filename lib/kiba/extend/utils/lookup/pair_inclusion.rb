# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      module Lookup
        class PairInclusion
          attr_reader :result

          def initialize(pair:, row:, mergerow: {})
            comparison_type = :include
            pair = pair.map { |e| e.split('::') }
            # convert row or mergerow fieldnames to symbols
            pair = pair.each { |arr| arr[1] = arr[1].to_sym if arr[0]['row'] }
            # fetch or convert values for comparison
            pair = pair.map do |arr|
              case arr[0]
              when 'row'
                row.fetch(arr[1], nil)
              when 'mergerow'
                mergerow.fetch(arr[1], nil)
              when 'revalue'
                comparison_type = :match
                Regexp.new(arr[1])
              when 'value'
                arr[1]
              end
            end

            if pair[0].nil?
              @result = false
            else

              case comparison_type
              when :include
                @result = pair[0].include?(pair[1])
              when :match
                @result = pair[0].match?(pair[1])
              end
            end
          end
        end
      end
    end
  end
end
