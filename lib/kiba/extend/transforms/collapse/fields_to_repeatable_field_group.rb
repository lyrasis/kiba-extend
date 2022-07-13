# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Collapse
        # Combines data from multiple fields following an expected naming pattern (shown in examples below) into
        #   final fields that are part of a repeatable fieldgroup.
        #
        # This transform can be seen as a more opinionated, structured  shorthand for
        #   {Collapse::FieldsWithCustomFieldmap}, which does not make the same assumptions about the field
        #   names/patterns involved.
        #
        # ## Background and default use/behavior
        #
        # As an example, let's use example source data:
        #
        # ```
        # {displayideas: 'blah', ideadate: '2022-07-07', creditline: 'from someone'}
        # ```
        #
        # We want data from :displayideas and :creditline to both get mapped to annotation note fields,
        #   and we want the annotation type and annotation date fields set as appropriate.
        #
        # In order to apply this transform, we must first get the source data into the expected format:
        #
        # ```
        # {
        #   idea_annotationtype: 'display idea',
        #   idea_annotationdate: '2022-07-07',
        #   idea_annotationnote: 'blah',
        #   cl_annotationtype: 'credit line',
        #   cl_annotationnote: 'from someone'
        # }
        # ```
        #
        # Requirements of this pattern:
        #
        # - consistent prefix indicating orig source data
        # - suffix is the eventual target field that the values will be combined into
        # - prefix and suffix separated by underscore
        #
        # Then we can use this transform as follows:
        #
        # ```
        # transform Collapse::FieldsToRepeatableFieldGroup,
        #   sources: %i[cl idea],
        #   targets: %i[annotationtype annotationnote annotationdate],
        #   delim: '|'
        # ```
        #
        # And the result will be:
        #
        # ```
        # {
        #   annotationtype: 'credit line|display idea',
        #   annotationnote: 'from someone|blah',
        #   annotationdate: '%NULLVALUE%'|2022-07-07'
        # }
        # ```
        #
        # ## Blank/null values (`:null_placeholder` parameter)
        #
        # By default, empty or nil values are converted to a string representing a null value. This behavior
        #   cannot be disabled. When `enforce_evenness: true` (the default),  null value strings are added to
        #   ensure the same number of values in each target field.
        #
        # The null placeholder string used by default is: `%NULLVALUE%.
        #
        # You can change this as follows:
        #
        # Source data:
        #
        # ```
        # [
        #   {
        #     a_foo: 'a|f', a_bar: 'a',
        #     b_foo: 'bf', b_bar: 'b',
        #     c_foo: '', c_bar: 'c',
        #     d_foo: 'd|', d_bar: nil
        #   }
        # ]
        # ```
        #
        # Use this transform as follows:
        #
        # ```
        # transform Collapse::FieldsToRepeatableFieldGroup,
        #   sources: %i[a b c d],
        #   targets: %i[foo bar],
        #   delim: '|',
        #   null_placeholder: 'BLANK'
        # ```
        #
        # And the result will be:
        #
        # ```
        # [
        #   {
        #   foo: 'a|f|bf|BLANK|d',
        #   bar: 'a|BLANK|b|c|BLANK'
        #   }
        # ]
        # ```
        # 
        # ## Automatic removal of grouped field with no values in group (`empty_groups` parameter)
        #
        # By default, `empty_groups: :delete`. This causes the {Clean::EmptyFieldGroups} transform (with
        #   `use_nullvalue: true`) to be applied after the target fields are compiled, so that, with the
        #   following source data:
        #
        # ```
        # [
        #   {a_foo: 'afoo', a_bar: 'abar', b_foo: 'bfoo', b_bar: 'bbar'},
        #   {a_foo: 'afoo', a_bar: 'abar', b_foo: nil, b_bar: ''},
        #   {a_foo: 'afoo', a_bar: 'abar', b_foo: nil, b_bar: '%NULLVALUE%'},
        #   {a_foo: 'afoo', a_bar: '%NULLVALUE%', b_foo: '%NULLVALUE%', b_bar: 'bbar'},
        #   {a_foo: nil, a_bar: nil, b_foo: nil, b_bar: ''},
        #   {a_foo: 'afoo', a_bar: 'abar', b_foo: 'bfoo'},
        # ]
        # ```
        #
        # And this usage:
        #
        # ```
        # transform Collapse::FieldsToRepeatableFieldGroup,
        #   sources: %i[a b],
        #   targets: %i[foo bar],
        #   delim: '|'
        # ```
        #
        # The result will be:
        #
        # ```
        # [
        #   {foo: 'afoo|bfoo', bar: 'abar|bbar'},
        #   {foo: 'afoo', bar: 'abar'},
        #   {foo: 'afoo|%NULLVALUE%', bar: '%NULLVALUE%|bbar'},
        #   {foo: nil, bar: nil},
        #   {foo: 'afoo|bfoo', bar: 'abar|%NULLVALUE%'}
        # ]
        # ```
        #
        # If you do not want empty field groups removed, do:
        #
        # ```
        # transform Cspace::FieldsToRepeatableFieldGroup,
        #   sources: %i[a b],
        #   targets: %i[foo bar],
        #   delim: '|',
        #   empty_groups: :retain
        # ```
        #
        # The result will be:
        #
        # ```
        # [
        #   {foo: 'afoo|bfoo', bar: 'abar|bbar'},
        #   {foo: 'afoo|', bar: 'abar|'},
        #   {foo: 'afoo|', bar: 'abar|%NULLVALUE%'},
        #   {foo: 'afoo|%NULLVALUE%', bar: '%NULLVALUE%|bbar'},
        #   {foo: nil, bar: nil},
        #   {foo: 'afoo|bfoo', bar: 'abar|'}
        # ]
        # ```
        #
        # ## Enforcing evenness
        #
        # When a field group is even, each field in the group contains the same number of values. For
        #   example:
        #
        #  {foo: 'af|bf|cf', bar: 'ab|bb|cb', baz: 'az|bz|cz'}
        #
        # Depending on your application, an uneven field group may or may not be a concern:
        #
        #  {foo: 'af|bf|cf', bar: 'ab|bb|cb', baz: 'az|zz|bz|cz'}
        #
        # `foo` and `bar` both have 3 values, while `baz` has 4. The assumption of a repeating
        #   field group is: `foo[0]` goes with `bar[0]` goes with `baz[0]`, so having an extra value in
        #   `baz` is a problem if you expect `bf`, `bb`, and `bz` to line up.
        #
        # For this reason the default behavior of this transform is to pad the number of values in each set
        #   of source fields to ensure all coming from `a_foo`, `a_bar`, and `a_baz` have the same number of
        #   values. This is done by appending `%NULLVALUE` to the field values as necessary to achieve
        #   evenness. So, before joining any values from different source fields: 
        #
        #  {a_foo: 'af', a_bar: 'ab', a_baz: 'az|zz'}
        #
        # is transformed to: 
        #
        #  {a_foo: 'af|%NULLVALUE%', a_bar: 'ab|%NULLVALUE%', a_baz: 'az|zz'}
        #
        # **You are always warned for each source having uneven values.** This is because the above padding
        #   seems to make sense, but we can't be sure it is what was intended. What if `af` and `ab` are
        #   intended to go with `zz` instead of `az`? Or what if, in this situation, you really want:
        #
        #  {a_foo: 'af|af', a_bar: 'ab|ab', a_baz: 'az|zz'}
        #
        # Only you can be sure, so you get a warning whenever a source gets padded to enforce evenness.
        #
        # **You can also turn off enforcement of evenness**. You will still be warned about all uneven
        #   sources, but no values will be appended and your field group will have uneven values. This
        #   is not recommended, as it causes other changes to behavior that may be unexpected. For example:
        #
        # With source data:
        #
        # ```
        # [
        #   {
        #     a_foo: 'a|f', a_bar: 'a',
        #     b_foo: 'bf', b_bar: 'b',
        #     c_foo: '', c_bar: 'c',
        #     d_foo: 'd|', d_bar: nil
        #   }
        # ]
        # ```
        #
        # And tranform:
        #
        # ```
        # transform Cspace::FieldsToRepeatableFieldGroup,
        #   sources: %i[a b],
        #   targets: %i[foo bar],
        #   delim: '|',
        #   enforce_evenness: false
        # ```
        #
        # The result will be:
        #
        # ```
        # [
        #   {
        #     foo: 'a|f|bf|%NULLVALUE%|d|%NULLVALUE%',
        #     bar: 'a|b|c|%NULLVALUE%'
        #   }
        # ]
        # ```
        #
        # Note that we did not pass in `empty_groups: retain`, but we get an empty group (the 4th
        #   value in `foo` and the final value in `bar`)
        #
        # This is because {Clean::EmptyFieldGroups} avoids making any changes when it detects
        #   uneven fields, because how the values should actually line up (and thus what is actually
        #   empty) is ambiguous.
        class FieldsToRepeatableFieldGroup
          # @param sources [Array<Symbol>] the list of original source fields that field group intermediate
          #   fields were derived from (with `source_targetfield` pattern)
          # @param targets [Array<Symbol>] the list of final field group fields that the
          #   intermediate fields will be combined into
          # @param delim [String] used to join multiple values in a field
          # @param null_placeholder [String] used to replace nil or empty values
          # @param empty_groups [:delete, :retain] treatment of empty field groups (i.e. all target field values in
          #   the same position are empty)
          # @param enforce_evenness [Boolean] whether to pad target fields with %NULLVALUE%s to ensure
          #   they all have the same number of values
          def initialize(
            sources:,
            targets:,
            delim: Kiba::Extend.delim,
            null_placeholder: '%NULLVALUE%',
            empty_groups: :delete,
            enforce_evenness: true
          )
            @sources = sources
            @targets = targets
            @delim = delim
            @null_placeholder = null_placeholder
            @nullval = '%NULLVALUE%'
            @empty_groups = empty_groups
            @enforce_evenness = enforce_evenness
            @field_group_cleaner = Clean::EmptyFieldGroups.new(
              groups: [targets],
              sep: delim,
              use_nullvalue: true)
            @delim_only_cleaner = Clean::DelimiterOnlyFields.new(delim: delim, use_nullvalue: nullval)
            @evenness_checker = Kiba::Extend::Transforms::Helpers::ValhashFieldEvennessChecker
            @evener  = Kiba::Extend::Transforms::Helpers::ValhashFieldEvennessFixer
          end
          
          def process(row)
            # {
            #   foo: {
            #     a: %w[a f],
            #     b: %w[bf],
            #     c: ['%NULLVALUE%'],
            #     d: %w[d f],
            #     e: ['%NULLVALUE%']
            #   },
            #   bar: {
            #     a: %w[a],
            #     b: %w[b],
            #     c: %w[c],
            #     d: ['%NULLVALUE%'],
            #     e: ['%NULLVALUE%']
            #   }
            # }
            valhash = populate_valhash(valhash_skeleton, row)

            if enforce_evenness && !values_even?(valhash, row)
              evener.call(valhash)
            end

            valhash.each{ |target, values| row[target] = values.values.join(delim) }
            field_group_cleaner.process(row) if empty_groups == :delete
            delim_only_cleaner.process(row)
            replace_nullvals(row) unless null_placeholder == nullval
            delete_sources(row)
            row
          end

          private

          attr_reader :sources, :targets, :delim, :null_placeholder, :nullval, :field_group_cleaner,
          :empty_groups, :enforce_evenness, :delim_only_cleaner, :evenness_checker, :evener

          def delete_sources(row)
            targets.each{ |target| sources.each{ |src| row.delete("#{src}_#{target}".to_sym) } }
          end

          def populate_sources(target, sources, row)
            sources.map{ |source| [source, processed_source_val(target, source, row)] }
              .to_h
          end
          
          def populate_valhash(valhash, row)
            valhash.map{ |target, sources| [target, populate_sources(target, sources, row)] }
              .to_h
          end

          def nullvalled_source_val(target, source, row)
            val = source_val(target, source, row)
            val.blank? ? nullval : val
          end

          def processed_source_val(target, source, row)
            nullvalled_source_val(target, source, row).split(delim, -1)
              .map{ |val| val.blank? ? nullval : val }
          end

          def replace_nullvals(row)
            targets.each do |target|
              val = row[target]
              next unless val[nullval]

              row[target] = val.gsub(nullval, null_placeholder)
            end
          end
          
          def source_val(target, source, row)
            row["#{source}_#{target}".to_sym]
          end

          def valhash_skeleton
            targets.map{ |target| [target, sources] }
              .to_h
          end

          def values_even?(valhash, row)
            result = evenness_checker.call(valhash)
            return true if result == :even

            result.each do |source|
              basemsg = "neven value counts in source field `#{source}` for targets `#{targets.join('/')}` in row:\n#{row.inspect}"
              msg = enforce_evenness ? "Padding u#{basemsg}" : "U#{basemsg}"
              warn("#{Kiba::Extend.warning_label}: #{msg}")
            end
            false
          end
        end
      end
    end
  end
end
