# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      module Lookup
        class CriteriaChecker
          attr_reader :result, :type

          def initialize(check_type:, config:, row:, mergerow: {}, sep: nil)
            @check_type = check_type
            @config = config
            @row = row
            @mergerow = mergerow
            @type = @config[:type] || :all
            bool = []

            @config[:fieldsets].each do |set|
              bool << Lookup::SetChecker.new(
                check_type: @check_type,
                set: set,
                row: @row,
                mergerow: @mergerow,
                sep: sep
              ).result
            end

            case @type
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
