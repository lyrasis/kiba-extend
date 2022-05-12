# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      module Lookup
        # :field_equal is an array of 2-element arrays to be compared.
        # The whole value of the first field/string must match the whole
        #   value of the second field/string
        # The elements in the pairwise arrays follow these formats:
        #   'row::fieldname' - field from workng row whose value
        #      should be compared
        #   'mergerow::fieldname' - field from merge row whose value(s)
        #      should be compared
        #   'value::string' - string against which to compare a field value
        #   'revalue::string' - string to be compared as a regular expression
        #      against a field value
        # It is assumed, but not enforced, that at least one of the pair will
        #   be a field
        class RowSelector
          def initialize(origrow:, mergerows: [], conditions: {}, sep: nil)
            @exclude = conditions[:exclude]
            @include = conditions[:include]

            @keeprows = mergerows.empty? ? origrow : mergerows
            @keeprows = mergerows.reject { |mrow| exclude?(origrow, mrow) } if @exclude
            @keeprows = [@keeprows.first] if @keeprows.size.positive? && @include && @include[:position] == 'first'
            @keeprows = @keeprows.select { |mrow| include?(origrow, mrow) } if @include
          end

          def result
            @keeprows
          end

          private

          def exclude?(row, mrow)
            bool = do_checks(@exclude, row, mrow)
            bool.flatten.any? ? true : false
          end

          def include?(row, mrow)
            bool = do_checks(@include, row, mrow)
            bool.include?(false) ? false : true
          end

          def do_checks(config, row, mrow)
            bool = []
            config.each do |chktype, value|
              case chktype
              when :field_empty
                bool << Lookup::CriteriaChecker.new(check_type: :emptiness, config: value, row: row,
                                                    mergerow: mrow).result
              when :field_equal
                bool << Lookup::CriteriaChecker.new(check_type: :equality, config: value, row: row,
                                                    mergerow: mrow).result
              when :multival_field_equal
                bool << Lookup::CriteriaChecker.new(check_type: :mvequality,
                                                    config: value,
                                                    row: row,
                                                    mergerow: mrow,
                                                    sep: sep).result
              when :field_include
                bool << Lookup::CriteriaChecker.new(check_type: :inclusion, config: value, row: row,
                                                    mergerow: mrow).result
              when :multival_field_include
                bool << Lookup::CriteriaChecker.new(check_type: :mvinclusion,
                                                    config: value,
                                                    row: row,
                                                    mergerow: mrow,
                                                    sep: sep).result
              when :position
                # do nothing
              end
            end
            bool
          end
        end
      end
    end
  end
end

  
