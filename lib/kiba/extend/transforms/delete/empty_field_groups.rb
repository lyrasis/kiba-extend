# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Delete
        class EmptyFieldGroups
          
          # @param groups [Array(Array(Symbol))] Each of the arrays inside groups should list all fields that are
          #   part of a repeating field group or field subgroup
          # @param delim [String] delimiter used to split/join field values
          # @param treat_as_null [nil, String, Array(String)] values aside from `nil` and `''` that should be
          #   treated as null/empty when removing empty field groups
          def initialize(groups:, delim: Kiba::Extend.delim, treat_as_null: Kiba::Extend.nullvalue)
            @groups = groups
            @delim = delim
            @null_vals = treat_as_null ? [treat_as_null].flatten.sort_by{ |v| v.length }.reverse : []
            @delim_only_cleaner = Delete::DelimiterOnlyFieldValues.new(
              fields: groups.flatten,
              delim: delim,
              treat_as_null: null_vals
            )
            @evenness_checkers = groups.map do |fields|
              Helpers::RowFieldEvennessChecker.new(fields: fields, delim: delim)
            end
            @value_getters = groups.map do |fields|
              Helpers::FieldValueGetter.new(fields: fields, delim: delim)
            end
          end

          # @private
          def process(row)
            delim_only_cleaner.process(row)
            groups.each_with_index do |group, idx|
              process_group(row, group, evenness_checkers[idx], value_getters[idx])
            end

            row
          end

          private

          attr_reader :groups, :delim, :null_vals,
            :delim_only_cleaner, :evenness_checkers, :value_getters

          def process_group(row, fields, evenness_checker, value_getter)
            # it's too dangerous/messing to try to process uneven rows this way
            return unless evenness_checker.call(row) == :even
            return if value_getter.call(row).empty?

            field_vals = value_getter.call(row)
            if field_vals.length == 1
              single_field_blank_remover(row, field_vals)
            else
              multi_field_blank_remover(row, field_vals)
            end
          end

          def delete_blank_indexes(row, field, vals, idxs)
            idxs.each{ |idx| vals.delete_at(idx) }
            val = vals.empty? ? nil : vals.join(delim)
            row[field] = val
          end
          
          def multi_field_blank_remover(row, field_vals)
            split_vals = field_vals.transform_values{ |vals| vals.split(delim, -1) }
            idxs = empty_indexes(split_vals)
            split_vals.each{ |field, vals| delete_blank_indexes(row, field, vals, idxs) }
          end
          
          def single_field_blank_remover(row, field_vals)
            field_vals.each do |field, vals|
              row[field] = vals.split(delim, -1)
                .reject{ |val| empty_val?(val) }
                .join(delim)
            end
          end

          def empty_indexes(vals)
            prep = prep_for_empty_index_identification(vals)
            analyzer = setup_index_analyzer(prep)
            populate_index_analyzer(prep, analyzer)
            # reverse sort so we delete elements backward so as not to mess up index count
            analyzer.select{ |idx, vals| vals.all?(:empty) }.keys.sort.reverse
          end

          def populate_index_analyzer(prepped_vals, analyzer)
            prepped_vals.values.each do |vals|
              vals.each_with_index{ |val, idx| analyzer[idx] << val }
            end
          end
          
          def setup_index_analyzer(prepped_vals)
            analyzer = {}
            prepped_vals.first[1].each_with_index{ |_e, idx| analyzer[idx] = [] }
            analyzer
          end
          
          def prep_for_empty_index_identification(vals)
            vals.dup
              .transform_values{ |vals| vals.map{ |val| empty_val?(val) ? :empty : :notempty } }
          end
          
          def empty_val?(str)
            [nil, '', null_vals].flatten.any?(str)
          end

          def add_null_values(str)
            return str if str.nil?

            padfront = str.start_with?(@sep) ? "%NULLVALUE%#{str}" : str
            padend = padfront.end_with?(@sep) ? "#{padfront}%NULLVALUE%" : padfront
            padded = padend.gsub("#{@sep}#{@sep}", "#{@sep}%NULLVALUE%#{@sep}")
            padded
          end

          # def all_empty?(group, index)
          #   thesevals = group.map { |arr| arr[index] }
          #     .map { |val| empty_val?(val) ? nil : val }
          #     .uniq
          #     .compact
          #   thesevals.empty? ? true : false
          # end
        end
      end
    end
  end
end


