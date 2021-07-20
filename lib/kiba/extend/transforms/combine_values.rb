module Kiba
  module Extend
    module Transforms
      module CombineValues
        ::CombineValues = Kiba::Extend::Transforms::CombineValues

        # Combines values from multiple columns together as specified in fieldmap parameter.
        #
        # Target field name can be the same as an existing field name.
        #
        # # Examples
        #
        # Input table:
        #
        # ```
        # | person                  | statusa               | date             | personb | statusb   | date2 | personc | statusc    | date3 |
        # |---------------------------------------------------------------------------------------------------------------------------------|
        # | jim                     | approved              | 2020             | bill    | requested | 2019  | terri   | authorized |  2018 |
        # | jim;mavis               | approved;             | 2020;2021        | bill    | requested | 2019  | terri   | authorized |  2018 |
        # | nil                     | acknowledged          | 2020             | jill    | requested | nil   | bill    | followup   |  2021 |
        # | %NULLVALUE%;%NULLVALUE% | acknowledged;approved | 2020;%NULLVALUE% | jill    | requested | nil   | bill    | followup   |  2019 |
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
        #              }, sep: ';'
        # ```
        #
        # Results in:
        #
        # ```
        # | person                            | status                                   | statusdate             |
        # |-----------------------------------|------------------------------------------|------------------------|
        # | jim;bill;terri                    | authorized;approved;requested            | 2020;2019;2018         |
        # | jim;mavis;bill;terri              | authorized;approved;;requested           | 2020;2021;2019;2018    |
        # | ;jill;bill                        | followup;acknowledged;requested          | 2020;;2021             |
        # | %NULLVALUE%;%NULLVALUE%;jill;bill | followup;acknowledged;approved;requested | 2020;%NULLVALUE%;;2019 |
        # ```
        #
        # ## NOTE
        # If it is important that the number of values in each target column match in each row, depending on the situation, you may need to employ %NULLVALUE% or other placeholder value to ensure this. For example, contrast row 3 and 4 of the example. Row 3 works because an empty column value gets treated as a single value. Thus, it sees 3 person, status, and statusdate values, even though one person and one date value are nil.
        #
        # If the person column of row 4 were like this:
        #
        # ```
        # | person  | statusa               | date | personb | statusb   | date2 | personc | statusc    | date3 |
        # |---------|-----------------------|------|---------|-----------|-------|---------|------------|-------|
        # | nil     | acknowledged;approved | 2020 | jill    | requested | nil   | bill    | followup   |  2019 |
        # ```
        #
        # Then output would be:
        #
        # ```
        # | person     | status                                   | statusdate |
        # |--------------------------------------------------------------------|
        # | ;jill;bill | followup;acknowledged;approved;requested | 2020;;2019 |
        # ```
        #
        # Depending on your requirements, this could be problematic because you now have 3 values in person and statusdate, but 4 values in status
        #
        # @todo Make transformer smarter about padding out blank values to the necessary number of blank values when combined.
        #   This sort of assumes there will always be the same number of source fields mapped to each target field, but one
        #   approach would be to find the max length (once split) of source fields in each row with index[i]:
        #   person (0), statusc (2), date (1). Then pad accordingly. We'd still have to make some assumption like
        #   "if there's 1 value in a column, but max ct of column values is 2, pad as '2020;' instead of ';2020'
        class AcrossFieldGroup
          # @param fieldmap [Hash] Instructions on how to combine source fields into target fields. See above for fuller explanation of Hash format expectations
          # @param sep [String] String to use in splitting/joining the values
          # @param delete_sources [Boolean] Whether to delete source columns after values have been combined in target columns
          #
          # # More on `fieldmap` parameter
          #
          # * `fieldmap` is a Hash
          # * Each key is a target field, given as a Symbol, into which values from multiple other fields will be combined
          # * Each value is an Array of Symbols. Each element of the array is a source field that will be mapped into the target field given as key. Order of source fields in this array controls the order in which the source fields are combined.
          # * There must be an equal number of source fields given in each source field Array
          #
          # @todo Raise error if unequal number of source fields given 
          def initialize(fieldmap:, sep:, delete_sources: true)
            @fieldmap = fieldmap
            @sep = sep
            @del = delete_sources
          end

          # @private
          def process(row)
            @fieldmap.each do |target, sources|
              vals = []
              sources.each do |source|
                srcval = row.fetch(source)
                vals << '' if srcval.nil? || srcval.empty? || srcval.match?(Regexp.new("^#{@sep}"))
                vals << srcval.split(@sep) unless srcval.nil? || srcval.empty?
                vals << '' if srcval.match?(Regexp.new("#{@sep}$")) unless srcval.nil? || srcval.empty?
                row.delete(source) unless source == target if @del
              end
              row[target] = vals.join(@sep)
            end
            row
          end
        end

        # Combine values from given fields into the target field.
        #
        # This is like the CONCATENATE function in many spreadsheets. The given `sep` value is used as a separator between the combined values.
        #
        # # Examples
        #
        # Input table:
        #
        # ```
        # | col1 | col2 | col3 |
        # |------+------+------|
        # | a    | b    | c    |
        # | d    | e    | nil  |
        # | nil  | f    | g    |
        # | nil  | h    |      |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform CombineValues::FromFieldsWithDelimiter, sources: %i[col1 col3], target: :combined,
        #    sep: ' - ', delete_sources: false
        # ```
        #
        # Results in:
        #
        # ```
        # | col1 | col2 | col3 | combined |
        # |------+------+------+----------|
        # | a    | b    | c    | a - c    |
        # | d    | e    | nil  | d        |
        # | nil  | f    | g    | g        |
        # | nil  | h    |      | nil      |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform CombineValues::FromFieldsWithDelimiter, sources: %i[col1 col3], target: :col1,
        #    sep: ' - ', prepend_source_field_name: true
        # ```
        #
        # Results in:
        #
        # ```
        # | col2 | col1                 |
        # +------+----------------------|
        # | b    | col1: a - col3: c    |
        # | e    | col1: d              |
        # | f    | col3: g              |
        # | h    | nil                  |
        # ```
        class FromFieldsWithDelimiter
          # @param sources [Array<Symbol>] Fields whose values are to be combined
          # @param target [Symbol] Field into which the combined value will be written. May be one of the source fields
          # @param sep [String] Value inserted between combined field values
          # @param prepend_source_field_name [Boolean] Whether to insert the source field name before its value in the combined value.
          # @param delete_sources [Boolean] Whether to delete the source fields after combining their values into the target field. If target field name is the same as one of the source fields, the target field is not deleted. 
          def initialize(sources:, target:, sep:, prepend_source_field_name: false, delete_sources: true)
            @sources = sources
            @target = target
            @sep = sep
            @del = delete_sources
            @prepend = prepend_source_field_name
          end

          # @private
          def process(row)
            vals = @sources.map{ |src| row.fetch(src, nil) }
              .map{ |v| v.blank? ? nil : v }
            
            if @prepend
              pvals = []
              vals.each_with_index do |val, i|
                val = "#{@sources[i]}: #{val}" unless val.nil?
                pvals << val
              end
              vals = pvals
            end
            val = vals.compact.join(@sep)
            val.empty? ? row[@target] = nil : row[@target] = val
            
            @sources.each{ |src| row.delete(src) unless src == @target } if @del
            row
          end
        end

        # Concatenates values of all fields in each record together into the target field, using the given string as value separator in the combined value
        #
        # # Example
        #
        # Input table:
        #
        # ```
        # | name   | sex | source  |
        # |--------+-----+---------|
        # | Weddy  | m   | adopted |
        # | Niblet | f   | hatched |
        # | Keet   | nil | hatched |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform CombineValues::FullRecord, target: :index
        # ```
        #
        # Results in:
        #
        # ```
        # | name   | sex | source  | index            |
        # |--------+-----+---------+------------------|
        # | Weddy  | m   | adopted | Weddy m adopted  |
        # | Niblet | f   | hatched | Niblet f hatched |
        # | Keet   | nil | hatched | Keet hatched     |
        # ```
        class FullRecord
          # @param target [Symbol] Field into which to write full record
          # @param sep [String] Value used to separate individual field values in combined target field
          def initialize(target:, sep: ' ')
            @target = target
            @sep = sep
          end

          # @private
          def process(row)
            vals = row.keys.map{ |k| row.fetch(k, nil) }
            vals = vals.compact
            if vals.empty?
              row[@target] = nil
            else
              row[@target] = vals.join(@sep)
            end
            row
          end
        end
      end
    end
  end
end
