# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      module Lookup
        class MultivalPairs
          attr_reader :result

          def initialize(pair:, row:, sep:, mergerow: {})
            @result = []
            pair = pair.map { |e| e.split('::') }
            # convert row or mergerow fieldnames to symbols
            pair = pair.each { |arr| arr[1] = arr[1].to_sym if arr[0]['row'] }
            # fetch or convert values for comparison
            pair = pair.map do |arr|
              case arr[0]
              when 'row'
                [row.fetch(arr[1], '')].map { |e| e.nil? || e.empty? ? '%comparenothing%' : e }
              when 'mvrow'
                row.fetch(arr[1], '').split(sep).map { |e| e.nil? || e.empty? ? '%comparenothing%' : e }
              when 'mergerow'
                [mergerow.fetch(arr[1], '')].map { |e| e.nil? || e.empty? ? '%comparenothing%' : e }
              when 'mvmergerow'
                mergerow.fetch(arr[1], '').split(sep).map { |e| e.nil? || e.empty? ? '%comparenothing%' : e }
              when 'revalue'
                "revalue::#{arr[1]}"
              when 'value'
                arr[1]
              end
            end
            pair[0].product(pair[1]).each do |mvpair|
              @result << mvpair.map { |e| e.start_with?('revalue') ? e : "value::#{e}" }
            end
          end
        end
      end
    end
  end
end

  
