# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Collapse
        # @since 2.9.0
        #
        # rubocop:todo Layout/LineLength
        # Combines values from multiple columns together as specified in fieldmap parameter.
        # rubocop:enable Layout/LineLength
        #
        # rubocop:todo Layout/LineLength
        # If you are collapsing fields into target fields that are part of repeatable field groups,
        # rubocop:enable Layout/LineLength
        #   {Collapse::FieldsToRepeatableFieldGroup} may be more appropriate.
        #
        # Target field name can be the same as an existing field name.
        #
        # # Examples
        #
        # Input table:
        #
        # ```
        # [
        #   {person: '', statusa: '', date: '',
        #    personb: '', statusb: '', date2: '',
        #    personc: '', statusc: '', date3: ''},
        #   {person: 'jim', statusa: 'approved', date: '2020',
        #    personb: 'bill', statusb: 'requested', date2: '2019',
        #    personc: 'terri', statusc: 'authorized', date3: '2018'},
        #   {person: 'jim|mavis', statusa: 'approved|', date: '2020|2021',
        #    personb: 'bill', statusb: 'requested', date2: '2019',
        #    personc: 'terri', statusc: 'authorized', date3: '2018'},
        #   {person: nil, statusa: 'acknowledged', date: '2020',
        #    personb: 'jill', statusb: 'requested', date2: nil,
        #    personc: 'bill', statusc: 'followup', date3: '2021'},
        # rubocop:todo Layout/LineLength
        #   {person: '%NULLVALUE%|%NULLVALUE%', statusa: 'acknowledged|approved', date: '2020|%NULLVALUE%',
        # rubocop:enable Layout/LineLength
        #    personb: 'jill', statusb: 'requested', date2: nil,
        #    personc: 'bill', statusc: 'followup', date3: '2019'}
        # ]
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Collapse::FieldsWithCustomFieldmap,
        #    fieldmap: {
        #                :person => %i[person personb personc],
        #                :status => %i[statusc statusa statusb],
        #                :statusdate => %i[date date2 date3]
        #              }, delim: '|'
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {person: '||',
        #    status: '|',
        #    statusdate: '',
        #    statusc: '', date2: '', date3: ''},
        #   {person: 'jim|bill|terri',
        #    status: 'approved|requested',
        #    statusdate: '2020',
        #   statusc: 'authorized', date2: '2019', date3: '2018'},
        #   {person: 'jim|mavis|bill|terri',
        #    status: 'approved||requested',
        #    statusdate: '2020|2021',
        #   statusc: 'authorized', date2: '2019', date3: '2018'},
        #   {person: '|jill|bill',
        #    status: 'acknowledged|requested',
        #    statusdate: '2020',
        #   statusc: 'followup', date2: nil, date3: '2021'},
        #   {person: '%NULLVALUE%|%NULLVALUE%|jill|bill',
        #    status: 'acknowledged|approved|requested',
        #    statusdate: '2020|%NULLVALUE%',
        #   statusc: 'followup', date2: nil, date3: '2019'}
        # ]
        # ```
        #
        # ## NOTE
        # rubocop:todo Layout/LineLength
        # If it is important that the number of values in each target column match in each row, depending on the
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   situation, you may need to employ %NULLVALUE% or other placeholder value to ensure this. For example,
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   contrast row 3 and 4 of the example. Row 3 works because an empty column value gets treated as a
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   single value. Thus, it sees 3 person, status, and statusdate values, even though one person and one
        # rubocop:enable Layout/LineLength
        #   date value are nil.
        #
        # If the person column of row 4 were like this:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # | person  | statusa               | date | personb | statusb   | date2 | personc | statusc    | date3 |
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # |---------|-----------------------|------|---------|-----------|-------|---------|------------|-------|
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # | nil     | acknowledged|approved | 2020 | jill    | requested | nil   | bill    | followup   |  2019 |
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Then output would be:
        #
        # ```
        # | person     | status                                   | statusdate |
        # |--------------------------------------------------------------------|
        # | |jill|bill | followup|acknowledged|approved|requested | 2020||2019 |
        # ```
        #
        # rubocop:todo Layout/LineLength
        # Depending on your requirements, this could be problematic because you now have 3 values in person and
        # rubocop:enable Layout/LineLength
        #   statusdate, but 4 values in status
        #
        # rubocop:todo Layout/LineLength
        # Otherwise, you can collapse fields in whatever way you like. For example, used in pipeline as:
        # rubocop:enable Layout/LineLength
        #
        # ```
        #  transform Collapse::FieldsWithCustomFieldmap,
        #    fieldmap: {
        #                :person => %i[person personb personc],
        #                :status => %i[statusa statusb],
        #                :statusdate => %i[date]
        #              }, delim: '|'
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {person: '||',
        #    status: '|',
        #    statusdate: '',
        #    statusc: '', date2: '', date3: ''},
        #   {person: 'jim|bill|terri',
        #    status: 'approved|requested',
        #    statusdate: '2020',
        #   statusc: 'authorized', date2: '2019', date3: '2018'},
        #   {person: 'jim|mavis|bill|terri',
        #    status: 'approved||requested',
        #    statusdate: '2020|2021',
        #   statusc: 'authorized', date2: '2019', date3: '2018'},
        #   {person: '|jill|bill',
        #    status: 'acknowledged|requested',
        #    statusdate: '2020',
        #   statusc: 'followup', date2: nil, date3: '2021'},
        #   {person: '%NULLVALUE%|%NULLVALUE%|jill|bill',
        #    status: 'acknowledged|approved|requested',
        #    statusdate: '2020|%NULLVALUE%',
        #   statusc: 'followup', date2: nil, date3: '2019'}
        # ]
        # ```
        #
        # # More on `fieldmap` parameter
        #
        # * `fieldmap` is a Hash
        # rubocop:todo Layout/LineLength
        # * Each key is a target field, given as a Symbol, into which values from multiple other fields will be
        # rubocop:enable Layout/LineLength
        #   combined
        # rubocop:todo Layout/LineLength
        # * Each value is an Array of Symbols. Each element of the array is a source field that will be mapped
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   into the target field given as key. Order of source fields in this array controls the order in which
        # rubocop:enable Layout/LineLength
        #   the source fields are combined.
        # rubocop:todo Layout/LineLength
        # * There must be an equal number of source fields given in each source field Array
        # rubocop:enable Layout/LineLength
        class FieldsWithCustomFieldmap
          include SingleWarnable

          # rubocop:todo Layout/LineLength
          # @param fieldmap [Hash{Symbol => Array<Symbol>}] Instructions on how to combine source fields into
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   target fields. See above for fuller explanation of Hash format expectations
          # rubocop:enable Layout/LineLength
          # @param delim [String] String to use in splitting/joining the values
          # rubocop:todo Layout/LineLength
          # @param delete_sources [Boolean] Whether to delete source columns after values have been combined in
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   target columns. **If a target column is the same as a source column, it will not be deleted.**
          # rubocop:enable Layout/LineLength
          def initialize(fieldmap:, delim:, delete_sources: true)
            @fieldmap = fieldmap
            @delim = delim
            @del = delete_sources
            setup_single_warning
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            fieldmap.each { |target, sources|
              row[target] = compile_source_values(sources, row)
            }
            delete_sources(row) if del
            row
          end

          private

          attr_reader :fieldmap, :delim, :del

          def compile_source_values(sources, row)
            sources.map { |source| source_value(source, row) }
              .flatten
              .join(delim)
          end

          def source_value(source, row)
            if row.keys.any?(source)
              val = row[source]
              return "" if val.blank?
              val.split(delim, -1)
            else
              # rubocop:todo Layout/LineLength
              add_single_warning("Source field `#{source}` missing; treating as nil value")
              # rubocop:enable Layout/LineLength
              ""
            end
          end

          def delete_sources(row)
            targets = fieldmap.keys
            fieldmap.values.flatten.each { |source|
              row.delete(source) unless targets.any?(source)
            }
          end
        end
      end
    end
  end
end
