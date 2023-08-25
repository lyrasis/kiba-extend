# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Delete
        # @note Only useful for multi-valued fields
        #
        # rubocop:todo Layout/LineLength
        # Deletes any empty values from the field. Supports `usenull` = true to treat the value of
        # rubocop:enable Layout/LineLength
        #   `Kiba::Extend.nullvalue` as empty
        #
        # # Examples
        #
        # Assuming `Kiba::Extend.nullvalue` = `%NULLVALUE%`, and input table:
        #
        # ```
        # | data             |
        # |------------------|
        # | abc;;;d e f      |
        # | ;;abc            |
        # | def;;;;          |
        # | ;;;;;            |
        # | ;;;%NULLVALUE%;; |
        # |                  |
        # | nil              |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Delete::EmptyFieldValues, fields: [:data], sep: ';'
        # ```
        #
        # Results in:
        #
        # ```
        # | data        |
        # |-------------|
        # | abc;d e f   |
        # | abc         |
        # | def         |
        # |             |
        # | %NULLVALUE% |
        # |             |
        # | nil         |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # transform Delete::EmptyFieldValues, fields: [:data], sep: ';', usenull: true
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Results in:
        #
        # ```
        # | data      |
        # |-----------|
        # | abc;d e f |
        # | abc       |
        # | def       |
        # |           |
        # |           |
        # |           |
        # | nil       |
        # ```
        #
        class EmptyFieldValues
          include Allable
          # @note `sep` will be removed in a future version. **DO NOT USE**
          # @param fields [Array<Symbol>,Symbol] field(s) to delete from
          # @param sep [String] **DEPRECATED; DO NOT USE**
          # rubocop:todo Layout/LineLength
          # @param delim [String] on which to split multivalued fields. Defaults to `Kiba::Extend.delim` if not provided.
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          # @param usenull [Boolean] whether to treat `Kiba::Extend.nullvalue` string as an empty value
          # rubocop:enable Layout/LineLength
          def initialize(fields:, sep: nil, delim: nil, usenull: false)
            @fields = [fields].flatten
            @usenull = usenull
            if sep && delim
              # rubocop:todo Layout/LineLength
              puts %(#{Kiba::Extend.warning_label}: Do not use both `sep` and `delim`. Prefer `delim`)
              # rubocop:enable Layout/LineLength
            elsif sep
              # rubocop:todo Layout/LineLength
              puts %(#{Kiba::Extend.warning_label}: The `sep` keyword is being deprecated in a future version. Change it to `delim` in your ETL code.)
              # rubocop:enable Layout/LineLength
              @delim = sep
            else
              @delim = delim || Kiba::Extend.delim
            end
          end

          # @param row [Hash{ Symbol => String, nil }]

          def process(row)
            finalize_fields(row) unless fields_set

            fields.each do |field|
              val = row.fetch(field)
              next if val.nil?

              row[field] = val.split(delim)
                .compact
                .reject { |str| Helpers.empty?(str, usenull) }
                .join(delim)
            end
            row
          end

          private

          attr_reader :fields, :delim, :usenull
        end
      end
    end
  end
end
