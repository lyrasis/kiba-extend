# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      module Lookup
        class FieldEmptiness
          attr_reader :result

          def initialize(field:, row:, mergerow:)
            h = { 'row' => row, 'mergerow' => mergerow }
            fvals = field.split('::')
            @field = fvals[1].to_sym
            @row = fvals[0]
            val = h[@row].fetch(@field, '')
            @result = val.nil? || val.empty? ? true : false
          end
        end
      end
    end
  end
end
