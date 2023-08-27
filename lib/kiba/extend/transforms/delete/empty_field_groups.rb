# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Delete
        # @since 2.9.0
        #
        # rubocop:todo Layout/LineLength
        # Deletes empty value from each field in a field group if values in that position in each field in the
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   field group are empty. For example, if the 3rd value in grouped fields annotationType,
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   annotationDate, and annotationNote are all blank, then the 3rd value from each field is deleted.
        # rubocop:enable Layout/LineLength
        #
        # Features/behaviors:
        #
        # rubocop:todo Layout/LineLength
        # - aims to keep field groups even (See {Warn::UnevenFields} for explanation of field group)
        # rubocop:enable Layout/LineLength
        #   evenness
        # rubocop:todo Layout/LineLength
        # - skips processing field groups found to be uneven, as it is impossible to know which
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   value is intended to go with which other values across the field group
        # rubocop:enable Layout/LineLength
        # - converts fields considered empty to nil
        # rubocop:todo Layout/LineLength
        # - considers delimiter-only fields to be empty. Runs {Delete::DelimiterOnlyFieldValues} to
        # rubocop:enable Layout/LineLength
        #   clear them.
        #
        # ## Examples
        #
        # Source data for both examples below:
        #
        # ```
        # [
        #   {aa: '', ab: '', bb: '', bc: '', bd: ''},
        #   {aa: 'n|', ab: nil, bb: '|e', bc: '|n', bd: '|e'},
        #   {aa: 'n', ab: '', bb: 'n', bc: 'e', bd: 'p'},
        #   {aa: 'n|e', ab: 'e|n', bb: 'n|e', bc: 'e|n', bd: 'ne|'},
        #   {aa: 'n|', ab: 'e|', bb: '|e', bc: 'n|e', bd: '|e'},
        #   {aa: '|', ab: '|', bb: 'e||n|', bc: 'n||e|', bd: 'e||p|'},
        # rubocop:todo Layout/LineLength
        #   {aa: '%NULLVALUE%', ab: '%NULLVALUE%', bb: '%NULLVALUE%|%NULLVALUE%', bc: nil, bd: '|'},
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   {aa: '|', ab: '', bb: '%NULLVALUE%|', bc: '%NULLVALUE%|%NULLVALUE%', bd: '%NULLVALUE%|a'},
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   {aa: '|', ab: '', bb: '%NULLVALUE%|', bc: '%NULLVALUE%|NULL', bd: '%NULLVALUE%|a'}
        # rubocop:enable Layout/LineLength
        # ]
        # ```
        #
        # Value of `Kiba::Extend.nullvalue` is `%NULLVALUE%`.
        #
        # ### Default behavior
        #
        # rubocop:todo Layout/LineLength
        # By default, this transform considers the value of `Kiba::Extend.nullvalue` to represent an empty
        # rubocop:enable Layout/LineLength
        #   value.
        #
        # Used in job as:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # transform Delete::EmptyFieldGroups, groups: [%i[aa ab], %i[bb bc bd]], delim: '|'
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {aa: nil, ab: nil, bb: nil, bc: nil, bd: nil},
        #   {aa: 'n', ab: nil, bb: 'e', bc: 'n', bd: 'e'},
        #   {aa: 'n', ab: nil, bb: 'n', bc: 'e', bd: 'p'},
        #   {aa: 'n|e', ab: 'e|n', bb: 'n|e', bc: 'e|n', bd: 'ne|'},
        #   {aa: 'n', ab: 'e', bb: '|e', bc: 'n|e', bd: '|e'},
        #   {aa: nil, ab: nil, bb: 'e|n', bc: 'n|e', bd: 'e|p'},
        #   {aa: nil, ab: nil, bb: nil, bc: nil, bd: nil},
        #   {aa: nil, ab: nil, bb: nil, bc: nil, bd: 'a'},
        #   {aa: nil, ab: nil, bb: nil, bc: 'NULL', bd: 'a'}
        # ]
        # ```
        #
        # ### Treat multiple strings as empty
        #
        # rubocop:todo Layout/LineLength
        # Note that the array given for `treat_as_null` here overrides the default value of that
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   parameter. If you want the value of `Kiba::Extend.nullvalue` to be one of the included
        # rubocop:enable Layout/LineLength
        #   values, you must specify it in the array given.
        #
        # Used in job as:
        #
        # ```
        # transform Delete::EmptyFieldGroups,
        #   groups: [%i[aa ab], %i[bb bc bd]],
        #   treat_as_null: ['NULL', Kiba::Extend.nullvalue],
        #   delim: '|'
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {aa: nil, ab: nil, bb: nil, bc: nil, bd: nil},
        #   {aa: 'n', ab: nil, bb: 'e', bc: 'n', bd: 'e'},
        #   {aa: 'n', ab: nil, bb: 'n', bc: 'e', bd: 'p'},
        #   {aa: 'n|e', ab: 'e|n', bb: 'n|e', bc: 'e|n', bd: 'ne|'},
        #   {aa: 'n', ab: 'e', bb: '|e', bc: 'n|e', bd: '|e'},
        #   {aa: nil, ab: nil, bb: 'e|n', bc: 'n|e', bd: 'e|p'},
        #   {aa: nil, ab: nil, bb: nil, bc: nil, bd: nil},
        #   {aa: nil, ab: nil, bb: nil, bc: nil, bd: 'a'},
        #   {aa: nil, ab: nil, bb: nil, bc: nil, bd: 'a'}
        # ]
        # ```
        #
        # ### Do not treat any strings except empty string (`''`) as empty
        #
        # Used in job as:
        #
        # ```
        # transform Delete::EmptyFieldGroups,
        #   groups: [%i[aa ab], %i[bb bc bd]],
        #   treat_as_null: nil,
        #   delim: '|'
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {aa: nil, ab: nil, bb: nil, bc: nil, bd: nil},
        #   {aa: 'n', ab: nil, bb: 'e', bc: 'n', bd: 'e'},
        #   {aa: 'n', ab: nil, bb: 'n', bc: 'e', bd: 'p'},
        #   {aa: 'n|e', ab: 'e|n', bb: 'n|e', bc: 'e|n', bd: 'ne|'},
        #   {aa: 'n', ab: 'e', bb: '|e', bc: 'n|e', bd: '|e'},
        #   {aa: nil, ab: nil, bb: 'e|n', bc: 'n|e', bd: 'e|p'},
        # rubocop:todo Layout/LineLength
        #   {aa: '%NULLVALUE%', ab: '%NULLVALUE%', bb: '%NULLVALUE%|%NULLVALUE%', bc: nil, bd: nil},
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   {aa: nil, ab: nil, bb: '%NULLVALUE%|', bc: '%NULLVALUE%|%NULLVALUE%', bd: '%NULLVALUE%|a'},
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   {aa: nil, ab: nil, bb: '%NULLVALUE%|', bc: '%NULLVALUE%|NULL', bd: '%NULLVALUE%|a'}
        # rubocop:enable Layout/LineLength
        # ]
        # ```
        class EmptyFieldGroups
          # rubocop:todo Layout/LineLength
          # @param groups [Array(Array(Symbol))] Each of the arrays inside groups should list all fields that are
          # rubocop:enable Layout/LineLength
          #   part of a repeating field group or field subgroup
          # @param delim [String] delimiter used to split/join field values
          # rubocop:todo Layout/LineLength
          # @param treat_as_null [nil, String, Array(String)] values aside from `nil` and `''` that should be
          # rubocop:enable Layout/LineLength
          #   treated as null/empty when removing empty field groups
          def initialize(groups:, delim: Kiba::Extend.delim,
            treat_as_null: Kiba::Extend.nullvalue)
            @groups = groups
            @delim = delim
            @null_vals = treat_as_null ? [treat_as_null].flatten.sort_by do |v|
                                           v.length
                                         end.reverse : []
            @delim_only_cleaner = Delete::DelimiterOnlyFieldValues.new(
              fields: groups.flatten,
              delim: delim,
              treat_as_null: null_vals
            )
            @evenness_checkers = groups.map do |fields|
              Helpers::FieldEvennessChecker.new(fields: fields, delim: delim)
            end
            @value_getters = groups.map do |fields|
              Helpers::FieldValueGetter.new(fields: fields, delim: delim)
            end
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            delim_only_cleaner.process(row)
            groups.each_with_index do |group, idx|
              process_group(row, group, evenness_checkers[idx],
                value_getters[idx])
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
            idxs.each { |idx| vals.delete_at(idx) }
            val = vals.empty? ? nil : vals.join(delim)
            row[field] = val
          end

          def multi_field_blank_remover(row, field_vals)
            split_vals = field_vals.transform_values do |vals|
              vals.split(delim, -1)
            end
            idxs = empty_indexes(split_vals)
            split_vals.each do |field, vals|
              delete_blank_indexes(row, field, vals, idxs)
            end
          end

          def single_field_blank_remover(row, field_vals)
            field_vals.each do |field, vals|
              row[field] = vals.split(delim, -1)
                .reject { |val| empty_val?(val) }
                .join(delim)
            end
          end

          def empty_indexes(vals)
            prep = prep_for_empty_index_identification(vals)
            analyzer = setup_index_analyzer(prep)
            populate_index_analyzer(prep, analyzer)
            # rubocop:todo Layout/LineLength
            # reverse sort so we delete elements backward so as not to mess up index count
            # rubocop:enable Layout/LineLength
            analyzer.select { |idx, vals| vals.all?(:empty) }.keys.sort.reverse
          end

          def populate_index_analyzer(prepped_vals, analyzer)
            prepped_vals.values.each do |vals|
              vals.each_with_index { |val, idx| analyzer[idx] << val }
            end
          end

          def setup_index_analyzer(prepped_vals)
            analyzer = {}
            prepped_vals.first[1].each_with_index do |_e, idx|
              analyzer[idx] = []
            end
            analyzer
          end

          def prep_for_empty_index_identification(vals)
            vals.dup
              .transform_values do |vals|
              vals.map do |val|
                empty_val?(val) ? :empty : :notempty
              end
            end
          end

          def empty_val?(str)
            [nil, "", null_vals].flatten.any?(str)
          end

          def add_null_values(str)
            return str if str.nil?

            padfront = str.start_with?(@sep) ? "%NULLVALUE%#{str}" : str
            # rubocop:todo Layout/LineLength
            padend = padfront.end_with?(@sep) ? "#{padfront}%NULLVALUE%" : padfront
            # rubocop:enable Layout/LineLength
            padend.gsub("#{@sep}#{@sep}", "#{@sep}%NULLVALUE%#{@sep}")
          end
        end
      end
    end
  end
end
