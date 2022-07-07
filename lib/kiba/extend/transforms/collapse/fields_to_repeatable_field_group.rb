# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Collapse
        # Combines data from multiple fields following an expected naming pattern (shown in examples below) into final
        #   fields that are part of a repeatable fieldgroup.
        #
        # This transform can be seen as a more opinionated shorthand for {{CombineValues::AcrossFieldGroup}}, which does
        #   not make the same assumptions about the field names/patterns involved.
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
        # transform Cspace::FieldsToRepeatableFieldGroup,
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
        # By default, the {{Clean::EmptyFieldGroups}} transform (with `use_nullvalue: true`) is applied by this transform after the
        #   target fields are compiled, so that, with the following source data:
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
        # transform Cspace::FieldsToRepeatableFieldGroup,
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
        class FieldsToRepeatableFieldGroup
          # @param sources [Array<Symbol>] the list of original source fields that field group intermediate
          #   fields were derived from (with `source_targetfield` pattern)
          # @param targets [Array<Symbol>] the list of final field group fields that the
          #   intermediate fields will be combined into
          # @param delim [String] used to join multiple values in a field
          # @param empty_groups [:delete, :retain] treatment of empty field groups (i.e. all target field values in
          #   the same position are empty)
          def initialize(sources:, targets:, delim: Kiba::Extend.delim, empty_groups: :delete)
            @sources = sources
            @targets = targets
            @delim = delim
            @empty_groups = empty_groups
            @field_group_cleaner = Clean::EmptyFieldGroups.new(
              groups: [targets],
              sep: delim,
              use_nullvalue: true)
            @delim_only_cleaner = Clean::DelimiterOnlyFields.new(delim: delim, use_nullvalue: true)
          end
          
          def process(row)
            targets.each do |target|
              row[target] = combined(row, target)
              temp_fields(target).each{ |field| row.delete(field) }
            end

            field_group_cleaner.process(row) if empty_groups == :delete
            delim_only_cleaner.process(row)
          end

          private

          attr_reader :sources, :targets, :delim, :field_group_cleaner, :empty_groups, :delim_only_cleaner

          def combined(row, target)
            values(row, target).join(delim)
          end

          def temp_fields(target)
            sources.map{ |source| "#{source}_#{target}".to_sym } 
          end

          def values(row, target)
            temp_fields(target).map{ |field| row[field] }
              .map{ |val| val.nil? ? '' : val }
          end
        end
      end
    end
  end
end
