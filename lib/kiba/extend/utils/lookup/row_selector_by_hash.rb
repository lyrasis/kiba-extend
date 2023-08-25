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
        class RowSelectorByHash
          def initialize(conditions: {}, sep: nil)
            @conditions = conditions
            @sep = sep

            @toexclude = conditions[:exclude]
            @toinclude = conditions[:include]
          end

          def call(origrow:, mergerows:)
            rowset = mergerows.empty? ? [origrow] : mergerows
            with_exclusions = do_exclusions(origrow, rowset)
            narrowed = get_first(with_exclusions)
            do_inclusions(origrow, narrowed)
          end

          def result
            keeprows
          end

          private

          attr_reader :conditions, :sep, :toexclude, :toinclude

          def do_exclusions(origrow, mergerows)
            return mergerows unless toexclude

            mergerows.reject { |mrow| exclude?(origrow, mrow) }
          end

          def do_inclusions(origrow, rows)
            return rows unless toinclude

            rows.select { |row| include?(origrow, row) }
          end

          def get_first(rows)
            # rubocop:todo Layout/LineLength
            return rows unless rows.length > 0 && toinclude && toinclude[:position] == "first"
            # rubocop:enable Layout/LineLength

            [rows.first]
          end

          def exclude?(row, mrow)
            bool = do_checks(toexclude, row, mrow)
            bool.flatten.any?
          end

          def include?(row, mrow)
            bool = do_checks(toinclude, row, mrow)
            !bool.include?(false)
          end

          def do_checks(config, row, mrow)
            bool = []
            config.each do |chktype, value|
              case chktype
              when :field_empty
                # rubocop:todo Layout/LineLength
                bool << Lookup::CriteriaChecker.new(check_type: :emptiness, config: value, row: row,
                  # rubocop:enable Layout/LineLength
                  mergerow: mrow).result
              when :field_equal
                # rubocop:todo Layout/LineLength
                bool << Lookup::CriteriaChecker.new(check_type: :equality, config: value, row: row,
                  # rubocop:enable Layout/LineLength
                  mergerow: mrow).result
              when :multival_field_equal
                bool << Lookup::CriteriaChecker.new(check_type: :mvequality,
                  config: value,
                  row: row,
                  mergerow: mrow,
                  sep: sep).result
              when :field_include
                # rubocop:todo Layout/LineLength
                bool << Lookup::CriteriaChecker.new(check_type: :inclusion, config: value, row: row,
                  # rubocop:enable Layout/LineLength
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
