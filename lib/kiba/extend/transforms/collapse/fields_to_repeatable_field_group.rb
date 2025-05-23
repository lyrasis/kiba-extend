# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Collapse
        # @since 2.9.0
        #
        # Combines data from multiple fields following an expected naming
        #   pattern (shown in examples below) into final fields that are part of
        #   a repeatable fieldgroup.
        #
        # This transform can be seen as a more opinionated, structured
        #   shorthand for {Collapse::FieldsWithCustomFieldmap}, which does not
        #   make the same assumptions about the field names/patterns involved,
        #   nor about field groups and field group evenness.
        #
        # Goes through the following steps:
        #
        # - Runs {Replace::EmptyFieldValues} to replace source fields values
        #   that are nil or empty (the full field value) with value of given for
        #   `null_placeholder`. This avoids odd situations where dropping fields
        #   because they are empty at this point introduces unevenness.
        # - If `enforce_evenness: true`, ensure all fields from a given source
        #   have the same number of values by running {Clean::EvenFieldValues}
        #   with `evener: even_val`, `treat_as_null: null_placeholder`, and
        #   `warn: warn_if_uneven`
        # - Uses {Helpers::FieldValueGetter} with `discard: []` (i.e. keep all
        #   values) to gather and combine values from source fields for a given
        #   target into the target value
        # - Deletes source fields
        # - Runs {Replace::EmptyFieldValues} on target fields, with
        #   `delim: delim` (turns on replacement of individual empty values in a
        #   multi-value string) and `value: null_placeholder`
        # - If `empty_groups: delete`, runs {Delete::EmptyFieldGroups} on target
        #   fields with `treat_as_null: [null_placeholder, even_val].uniq`
        # - Runs {Delete::DelimiterOnlyFieldValues} on target fields with
        #   `treat_as_null: null_placeholder`
        #
        # ## General example
        #
        # As an example, let's use example original source data:
        #
        # ~~~
        # {
        #   displayideas: 'blah',
        #   ideadate: '2022-07-07',
        #   creditline: 'from someone'
        # }
        # ~~~
        #
        # We want data from :displayideas and :creditline to both get mapped to
        #   annotation note fields, and we want the annotation type and
        #   annotation date fields set as appropriate.
        #
        # In order to apply this transform, we must first get the source data
        #   into the expected format (This must be achieved via other transforms
        #   before applying this one):
        #
        # ~~~
        # {
        #   idea_annotationtype: 'display idea',
        #   idea_annotationdate: '2022-07-07',
        #   idea_annotationnote: 'blah',
        #   cl_annotationtype: 'credit line',
        #   cl_annotationnote: 'from someone'
        # }
        # ~~~
        #
        # Requirements of this pattern:
        #
        # - consistent prefix indicating orig source data
        # - suffix is the eventual target field that the values will be combined
        #   into
        # - prefix and suffix separated by underscore
        #
        # Then we can use this transform as follows:
        #
        # ~~~
        # transform Collapse::FieldsToRepeatableFieldGroup,
        #   sources: %i[cl idea],
        #   targets: %i[annotationtype annotationnote annotationdate],
        #   delim: '|'
        # ~~~
        #
        # And the result will be:
        #
        # ~~~
        # {
        #   annotationtype: 'credit line|display idea',
        #   annotationnote: 'from someone|blah',
        #   annotationdate: '%NULLVALUE%'|2022-07-07'
        # }
        # ~~~
        #
        # ## Specific examples/parameter effects
        #
        # ### Blank/null values (`:null_placeholder` parameter)
        #
        # Prior to any other processing, empty or nil whole-field values are
        #   converted to a string representing a null value. After target fields
        #   are compiled, any individual null/empty values within a joined
        #   String is also converted to this null-value representing string.
        #   This behavior cannot be disabled.
        #
        # The null placeholder string used by default is the value of
        #   `Kiba::Extend.nullvalue` (default = '%NULLVALUE%')
        #
        # You can change this as follows:
        #
        # Source data:
        #
        # ~~~
        # [
        #   {
        #     a_foo: 'a|f', a_bar: 'a',
        #     b_foo: 'bf', b_bar: 'b',
        #     c_foo: '', c_bar: 'c',
        #     d_foo: 'd|', d_bar: nil
        #   }
        # ]
        # ~~~
        #
        # Use this transform as follows:
        #
        # ~~~
        # transform Collapse::FieldsToRepeatableFieldGroup,
        #   sources: %i[a b c d],
        #   targets: %i[foo bar],
        #   delim: '|',
        #   null_placeholder: 'BLANK'
        # ~~~
        #
        # And the result will be:
        #
        # ~~~
        # [
        #   {
        #     foo: 'a|f|bf|BLANK|d',
        #     bar: 'a|%NULLVALUE%|b|c|BLANK'
        #   }
        # ]
        # ~~~
        #
        # **Note that there are still some '%NULLVALUE%'s in there.** This is
        #   because we did not change the `even_val` parameter from its default
        #   value. The '%NULLVALUE%'s were added to achieve even field values.
        #
        # ### Automatic removal of grouped field with no values in group
        #
        # By default, `empty_groups: :delete`. This causes the
        #   {Clean::EmptyFieldGroups} transform (with `use_nullvalue: true`) to
        #   be applied after the target fields are compiled, so that, with the
        #   following source data:
        #
        # ~~~
        # [
        #   {a_foo: 'afoo', a_bar: 'abar', b_foo: 'bfoo', b_bar: 'bbar'},
        #   {a_foo: 'afoo', a_bar: 'abar', b_foo: nil, b_bar: ''},
        #   {a_foo: 'afoo', a_bar: 'abar', b_foo: nil, b_bar: '%NULLVALUE%'},
        #   {a_foo: 'afoo', a_bar: '%NULLVALUE%', b_foo: '%NULLVALUE%',
        #     b_bar: 'bbar'},
        #   {a_foo: nil, a_bar: nil, b_foo: nil, b_bar: ''},
        #   {a_foo: 'afoo', a_bar: 'abar', b_foo: 'bfoo'},
        # ]
        # ~~~
        #
        # And this usage:
        #
        # ~~~
        # transform Collapse::FieldsToRepeatableFieldGroup,
        #   sources: %i[a b],
        #   targets: %i[foo bar],
        #   delim: '|'
        # ~~~
        #
        # The result will be:
        #
        # ~~~
        # [
        #   {foo: 'afoo|bfoo', bar: 'abar|bbar'},
        #   {foo: 'afoo', bar: 'abar'},
        #   {foo: 'afoo', bar: 'abar'},
        #   {foo: 'afoo|%NULLVALUE%', bar: '%NULLVALUE%|bbar'},
        #   {foo: nil, bar: nil},
        #   {foo: 'afoo|bfoo', bar: 'abar|%NULLVALUE%'}
        # ]
        # ~~~
        #
        # If you do not want empty field groups removed, do:
        #
        # ~~~
        # transform Collapse::FieldsToRepeatableFieldGroup,
        #   sources: %i[a b],
        #   targets: %i[foo bar],
        #   delim: '|',
        #   empty_groups: :retain
        # ~~~
        #
        # The result will be:
        #
        # ~~~
        # [
        #   {foo: 'afoo|bfoo', bar: 'abar|bbar'},
        #   {foo: 'afoo|%NULLVALUE%', bar: 'abar|%NULLVALUE%'},
        #   {foo: 'afoo|%NULLVALUE%', bar: 'abar|%NULLVALUE%'},
        #   {foo: 'afoo|%NULLVALUE%', bar: '%NULLVALUE%|bbar'},
        #   {foo: nil, bar: nil},
        #   {foo: 'afoo|bfoo', bar: 'abar|%NULLVALUE%'}
        # ]
        # ~~~
        #
        # ## Enforcing evenness
        #
        # See {Warn::UnevenFields} for explanation of what is meant by evenness.
        #
        # See {Clean::EvenFieldValues} for details on how fields are evened if
        #   `enforce_evenness: true`.
        #
        # With source data:
        #
        # ~~~
        # [
        #   {
        #     a_foo: 'a|f', a_bar: 'a',
        #     b_foo: 'bf', b_bar: 'b',
        #     c_foo: '', c_bar: 'c',
        #     d_foo: 'd|', d_bar: nil
        #   }
        # ]
        # ~~~
        #
        # And tranform:
        #
        # ~~~
        # transform Collapse::FieldsToRepeatableFieldGroup,
        #   sources: %i[a b],
        #   targets: %i[foo bar],
        #   delim: '|',
        #   enforce_evenness: false
        # ~~~
        #
        # The result will be:
        #
        # ~~~
        # [
        #   {
        #     foo: 'a|f|bf|%NULLVALUE%|d|%NULLVALUE%',
        #     bar: 'a|b|c|%NULLVALUE%'
        #   }
        # ]
        # ~~~
        #
        # Note that we did not pass in `empty_groups: retain`, but we get an
        #   empty group (the 4th value in `foo` and the 4th/final value in
        #   `bar`)
        #
        # This is because {Clean::EmptyFieldGroups} avoids making any changes
        #   when it detects uneven fields, because how the values should
        #   actually line up (and thus what is actually empty) is ambiguous.
        class FieldsToRepeatableFieldGroup
          # @param sources [Array<Symbol>] the list of original source fields
          #   that field group intermediate fields were derived from (with
          #   `source_targetfield` pattern)
          # @param targets [Array<Symbol>] the list of final field group fields
          #   that the intermediate fields will be combined into
          # @param delim [String] used to split/join multiple values in a field
          # @param null_placeholder [String] used to replace nil or empty values
          # @param even_val [:value, String] passed as `evener` parameter to
          #   {Clean::EvenFieldValues} when `enforce_evenness: true`.
          # @param empty_groups [:delete, :retain] treatment of empty field
          #   groups (i.e. all target field values in the same position are
          #   empty)
          # @param enforce_evenness [Boolean] whether to pad target fields with
          #   %NULLVALUE%s to ensure they all have the same number of values
          # @param warn_if_uneven [Boolean] whether {Clean::EvenFieldValues}
          #   should print warnings about uneven field groups to STDOUT
          def initialize(
            sources:,
            targets:,
            delim: Kiba::Extend.delim,
            null_placeholder: Kiba::Extend.nullvalue,
            even_val: Kiba::Extend.nullvalue,
            empty_groups: :delete,
            enforce_evenness: true,
            warn_if_uneven: true
          )
            @sources = sources
            @targets = targets
            @delim = delim
            @null_placeholder = null_placeholder
            @even_val = even_val
            @empty_groups = empty_groups
            @enforce_evenness = enforce_evenness
            @warn_if_uneven = warn_if_uneven

            @srcfieldgroups = sources.map do |source|
              targets.map do |target|
                field_name(source, target)
              end
            end
            @srcemptyreplacers = srcfieldgroups.map do |grp|
              Kiba::Extend::Transforms::Replace::EmptyFieldValues.new(
                fields: grp,
                value: null_placeholder
              )
            end
            @srceveners = srcfieldgroups.map do |grp|
              Kiba::Extend::Transforms::Clean::EvenFieldValues.new(
                fields: grp,
                evener: even_val,
                delim: delim,
                warn: warn_if_uneven,
                treat_as_null: null_placeholder
              )
            end
            @to_combine = targets.map do |target|
              [target,
                Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
                  fields: sources.map { |src| field_name(src, target) },
                  delim: delim,
                  discard: []
                )]
            end.to_h
            @field_group_cleaner = Delete::EmptyFieldGroups.new(
              groups: [targets],
              delim: delim,
              treat_as_null: empty_field_group_treat_as_null
            )
            @delim_only_cleaner = Delete::DelimiterOnlyFieldValues.new(
              fields: targets, delim: delim, treat_as_null: null_placeholder
            )
            @empty_replacer = Replace::EmptyFieldValues.new(
              fields: targets,
              delim: delim,
              value: null_placeholder
            )
          end

          def process(row)
            srcemptyreplacers.each { |replacer| replacer.process(row) }
            if enforce_evenness
              srceveners.each { |e| e.process(row) }
            end
            to_combine.each do |target, getter|
              row[target] = getter.call(row).values.join(delim)
            end
            delete_sources(row)
            empty_replacer.process(row)
            field_group_cleaner.process(row) if empty_groups == :delete
            delim_only_cleaner.process(row)
            row
          end

          private

          attr_reader :sources, :targets,
            :srcfieldgroups, :even_val, :srceveners, :srcemptyreplacers,
            :delim, :null_placeholder, :field_group_cleaner,
            :empty_groups, :enforce_evenness, :delim_only_cleaner,
            :evenness_checker, :evener, :to_combine, :empty_replacer

          def delete_sources(row)
            targets.each do |target|
              sources.each do |src|
                row.delete(:"#{src}_#{target}")
              end
            end
          end

          def empty_field_group_treat_as_null
            return null_placeholder if even_val == :value
            return null_placeholder if even_val == null_placeholder

            [null_placeholder, even_val]
          end

          def field_name(source, target)
            :"#{source}_#{target}"
          end
        end
      end
    end
  end
end
