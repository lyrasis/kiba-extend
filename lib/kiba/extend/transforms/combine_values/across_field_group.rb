# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module CombineValues
        # Combines values from multiple columns together as specified in fieldmap parameter.
        #
        # Target field name can be the same as an existing field name.
        #
        # # Examples
        #
        # Input table:
        #
        # ```
        # [
        # {person: '', statusa: '', date: '',
        #  personb: '', statusb: '', date2: '',
        #  personc: '', statusc: '', date3: ''},
        # {person: 'jim', statusa: 'approved', date: '2020',
        #  personb: 'bill', statusb: 'requested', date2: '2019',
        #  personc: 'terri', statusc: 'authorized', date3: '2018'},
        # {person: 'jim|mavis', statusa: 'approved|', date: '2020|2021',
        #  personb: 'bill', statusb: 'requested', date2: '2019',
        #  personc: 'terri', statusc: 'authorized', date3: '2018'},
        # {person: nil, statusa: 'acknowledged', date: '2020',
        #  personb: 'jill', statusb: 'requested', date2: nil,
        #  personc: 'bill', statusc: 'followup', date3: '2021'},
        # {person: '%NULLVALUE%|%NULLVALUE%', statusa: 'acknowledged|approved', date: '2020|%NULLVALUE%',
        #  personb: 'jill', statusb: 'requested', date2: nil,
        #  personc: 'bill', statusc: 'followup', date3: '2019'}
        # ]
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform CombineValues::AcrossFieldGroup,
        #    fieldmap: {
        #                :person => %i[person personb personc],
        #                :status => %i[statusc statusa statusb],
        #                :statusdate => %i[date date2 date3]
        #              }, sep: '|'
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
        # If it is important that the number of values in each target column match in each row, depending on the
        #   situation, you may need to employ %NULLVALUE% or other placeholder value to ensure this. For example,
        #   contrast row 3 and 4 of the example. Row 3 works because an empty column value gets treated as a
        #   single value. Thus, it sees 3 person, status, and statusdate values, even though one person and one
        #   date value are nil.
        #
        # If the person column of row 4 were like this:
        #
        # ```
        # | person  | statusa               | date | personb | statusb   | date2 | personc | statusc    | date3 |
        # |---------|-----------------------|------|---------|-----------|-------|---------|------------|-------|
        # | nil     | acknowledged|approved | 2020 | jill    | requested | nil   | bill    | followup   |  2019 |
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
        # Depending on your requirements, this could be problematic because you now have 3 values in person and
        #   statusdate, but 4 values in status
        #
        # Otherwise, you can collapse fields in whatever way you like. For example, used in pipeline as:
        #
        # ```
        #  transform CombineValues::AcrossFieldGroup,
        #    fieldmap: {
        #                :person => %i[person personb personc],
        #                :status => %i[statusa statusb],
        #                :statusdate => %i[date]
        #              }, sep: '|'
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
        # * Each key is a target field, given as a Symbol, into which values from multiple other fields will be
        #   combined
        # * Each value is an Array of Symbols. Each element of the array is a source field that will be mapped
        #   into the target field given as key. Order of source fields in this array controls the order in which
        #   the source fields are combined.
        # * There must be an equal number of source fields given in each source field Array
        class AcrossFieldGroup
          include SingleWarnable
          
          # @param fieldmap [Hash{Symbol => Array<Symbol>}] Instructions on how to combine source fields into
          #   target fields. See above for fuller explanation of Hash format expectations
          # @param sep [String] String to use in splitting/joining the values
          # @param delete_sources [Boolean] Whether to delete source columns after values have been combined in
          #   target columns. **If a target column is the same as a source column, it will not be deleted.**
          def initialize(fieldmap:, sep:, delete_sources: true)
            @fieldmap = fieldmap
            @sep = sep
            @del = delete_sources
            setup_single_warning
          end

          # @private
          def process(row)
            fieldmap.each{ |target, sources| row[target] = compile_source_values(sources, row) }
            delete_sources(row) if del
            row
          end

          private

          attr_reader :fieldmap, :sep, :del

          def compile_source_values(sources, row)
            sources.map{ |source| source_value(source, row) }
              .flatten
              .join(sep)
          end

          def source_value(source, row)
            if row.keys.any?(source)
              val = row[source]
              return '' if val.blank?
              val.split(sep, -1)
            else
              add_single_warning("Source field `#{source}` missing")
              ''
            end
          end

          def delete_sources(row)
            targets = fieldmap.keys
            fieldmap.values.flatten.each{ |source| row.delete(source) unless targets.any?(source) }
          end
        end
      end
    end
  end
end
