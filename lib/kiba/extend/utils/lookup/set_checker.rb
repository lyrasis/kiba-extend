# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      module Lookup
        class SetChecker
          attr_reader :set_type, :result

          def initialize(check_type:, set:, row:, mergerow: {}, sep: nil)
            @check_type = check_type
            @set_type = set[:type] || :any
            bool = []
            case @check_type
            when :equality
              set[:matches].each do |pair|
                chk = pair.select { |e| e.start_with?("mv") }
                if chk.empty?
                  bool << Lookup::PairEquality.new(
                    pair: pair,
                    row: row,
                    mergerow: mergerow
                  ).result
                else
                  bool << Lookup::SetChecker.new(
                    check_type: :equality,
                    set: {
                      type: :any,
                      matches: Lookup::MultivalPairs.new(pair: pair, row: row,
                        mergerow: mergerow, sep: sep).result
                    },
                    row: {}
                  )
                end
              end
            when :emptiness
              set[:fields].each do |field|
                bool << Lookup::FieldEmptiness.new(
                  field: field,
                  row: row,
                  mergerow: mergerow
                ).result
              end
            when :inclusion
              set[:includes].each do |pair|
                bool << Lookup::PairInclusion.new(
                  pair: pair,
                  row: row,
                  mergerow: mergerow
                ).result
              end
            end

            case @set_type
            when :any
              @result = bool.any?
            when :all
              @result = !bool.any?(false)
            end
          end
        end
      end
    end
  end
end
