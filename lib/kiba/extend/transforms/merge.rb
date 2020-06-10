module Kiba
  module Extend
    module Transforms
      module Merge
        ::Merge = Kiba::Extend::Transforms::Merge


        class ConstantValue
          def initialize(target:, value:)
            @target = target
            @value = value
          end

          def process(row)
            row[@target] = @value
            row
          end
        end

        # How the conditions are applied
        #  :fields_empty
        #    ALL fields listed must be nil or empty
        #  :fields_populated
        #    ALL fields listed must be populated
        #  :fields_match_regexp
        #    Multiple match values may be given to test for a single field
        #    ALL fields listed must match at least one of its match values
        class ConstantValueConditional
          def initialize(target:, value:, conditions: {})
            @target = target
            @value = value
            @conditions = conditions
          end

          def process(row)
            row[@target] = @value if conditions_met?(row)
            row
          end

          private

          def conditions_met?(row)
            results = []
            @conditions.each do |type, config|
              case type
              when :fields_empty
                results << check_emptiness(row, config)
              when :fields_populated
                results << check_populated(row, config)
              when :fields_match_regexp
                results << check_regexp_matches(row, config)
              end
            end
            results.any?(false) ? false : true
          end

          def check_emptiness(row, config)
            results = []
            config.each do |field|
              val = row.fetch(field)
              ( val.nil? || val.empty? ) ? results << true : results << false
            end
            results.any?(false) ? false : true
          end

          def check_populated(row, config)
            results = []
            config.each do |field|
              val = row.fetch(field)
              ( val.nil? || val.empty? ) ? results << false : results << true
            end
            results.any?(false) ? false : true
          end

          def check_regexp_matches(row, config)
            results = []
            config.each do |field, matches|
              field_results = []
              val = row.fetch(field)
              if val.nil? || val.empty?
                results << false
              else
                matches.each do |match|
                  re = Regexp.new(match)
                  val.match?(re) ? field_results << true : field_results << false
                end
              end
              field_results.any?(true) ? results << true : results << false
            end
            results.any?(false) ? false : true
          end
        end
        
        class CountOfMatchingRows
          def initialize(lookup:, keycolumn:, targetfield:,
                         exclusion_criteria: {},
                         selection_criteria: {}
                        )
            @lookup = lookup
            @keycolumn = keycolumn
            @target = targetfield
            @exclude = exclusion_criteria
            @include = selection_criteria
          end

          def process(row)
            id = row.fetch(@keycolumn)
            merge_rows = Lookup::RowSelector.new(
              origrow: row,
              mergerows: @lookup.fetch(id, []),
              exclude: @exclude,
              include: @include
            ).result
            row[@target] = merge_rows.size
            row
          end
        end
        
        # used when lookup may return an array of rows from which values should be merged
        #  into the target, AND THE TARGET IS MULTIVALUED
        class MultiRowLookup
          def initialize(fieldmap:, constantmap: {}, lookup:, keycolumn:,
                         exclusion_criteria: {}, selection_criteria: {}, delim: DELIM)
            @fieldmap = fieldmap # hash of looked-up values to merge in for each merged-in row
            @constantmap = constantmap #hash of constants to add for each merged-in row
            @lookup = lookup #lookuphash; should be created with csv_to_multi_hash
            @keycolumn = keycolumn #column in main table containing value expected to be lookup key
            @exclusion_criteria = exclusion_criteria #hash of constraints a row must NOT meet in order to be merged
            @selection_criteria = selection_criteria #hash of contraints a rom must meet in order to be merged
            @delim = delim
          end

          def process(row)
            id = row.fetch(@keycolumn)
            fh = {}
            ch = {}
            @fieldmap.each_key{ |k| fh[k] = [] }
            @constantmap.each_key{ |k| ch[k] = [] }

            merge_rows = Lookup::RowSelector.new(
              origrow: row,
              mergerows: @lookup.fetch(id, []),
              exclude: @exclusion_criteria,
              include: @selection_criteria
            ).result
            
            merge_rows.each do |mrow|
              @fieldmap.each do |target, source|
                val = mrow.fetch(source, '')
                fh[target] << val unless val.nil? || val.empty?
              end
              @constantmap.each{ |target, value| ch[target] << value }
            end

            chk = @fieldmap.map{ |target, source| fh[target].size }.uniq.sort

            if chk == [0]
              fh.each{ |target, arr| row[target] = nil }
              ch.each{ |target, arr| row[target] = nil }
            else
              fh.each{ |target, arr| row[target] = arr.join(@delim) }
              ch.each{ |target, arr| row[target] = arr.join(@delim) }
            end
            row
          end
        end
      end # module Merge
    end #module Transforms
  end #module Extend
end #module Kiba
