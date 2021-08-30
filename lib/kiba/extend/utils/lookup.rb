# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      module Lookup
        ::Lookup = Kiba::Extend::Utils::Lookup
        extend self
        # use when keycolumn values are unique
        # creates hash with keycolumn value as key and csv-row-as-hash as the value
        def csv_to_hash_deprecated(file:, keycolumn:, csvopt: {})
          CSV.foreach(File.expand_path(file), csvopt).each_with_object({}) do |r, memo|
            memo[r.fetch(keycolumn, nil)] = r.to_h
          end
        end

        # use when keycolumn values are not unique
        # creates hash with keycolumn value as key and array of csv-rows-as-hashes as the value
        def csv_to_hash(**args)
          CSV.foreach(File.expand_path(args[:file]), args[:csvopt]).each_with_object({}) do |r, memo|
            k = r.fetch(args[:keycolumn], nil)
            if memo.key?(k)
              memo[k] << r.to_h
            else
              memo[k] = [r.to_h]
            end
          end
        end

        alias_method :csv_to_multi_hash, :csv_to_hash

        class SetChecker
          attr_reader :set_type, :result

          def initialize(check_type:, set:, row:, mergerow: {}, sep: nil)
            @check_type = check_type
            @set_type = set[:type] || :any
            bool = []
            case @check_type
            when :equality
              set[:matches].each do |pair|
                chk = pair.select { |e| e.start_with?('mv') }
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
                      matches: Lookup::MultivalPairs.new(pair: pair, row: row, mergerow: mergerow, sep: sep).result
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
              @result = bool.any? ? true : false
            when :all
              @result = bool.any?(false) ? false : true
            end
          end
        end

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

        class PairEquality
          attr_reader :result

          def initialize(pair:, row:, mergerow: {})
            comparison_type = :equals
            pair = pair.map { |e| e.split('::') }
            # convert row or mergerow fieldnames to symbols
            pair = pair.each { |arr| arr[1] = arr[1].to_sym if arr[0]['row'] }
            # fetch or convert values for comparison
            pair = pair.map do |arr|
              case arr[0]
              when 'row'
                row.fetch(arr[1], '%field does not exist%')
              when 'mergerow'
                mergerow.fetch(arr[1], '%field does not exist%')
              when 'revalue'
                comparison_type = :match
                arr[1] = "^#{arr[1]}$"
                Regexp.new(arr[1])
              when 'value'
                arr[1]
              end
            end

            unless pair.include?(nil) && pair.include?('')
              # replace nil value with empty string for comparison
              pair = pair.map { |e| e = e.nil? ? '' : e }
            end

            case comparison_type
            when :equals
              @result = pair[0] == pair[1]
            when :match
              @result = pair[0].match?(pair[1])
            end
          end
        end

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
              @result = bool.any? ? true : false
            when :all
              @result = bool.any?(false) ? false : true
            end
          end
        end

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
