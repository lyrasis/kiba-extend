# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Delete
        # Deletes all fields except the one(s) passed in `fields` parameter.
        #
        # # Examples
        #
        # Input table:
        #
        # ```
        # | a | b | c |
        # |---+---+---|
        # | 1 | 2 | 3 |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Delete::FieldsExcept, fields: %i[a c]
        # ```
        #
        # Results in:
        #
        # ```
        # | a | c |
        # |---+---|
        # | 1 | 3 |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Delete::FieldsExcept, fields: :b
        # ```
        #
        # Results in:
        #
        # ```
        # | b |
        # |---|
        # | 2 |
        # ```
        #
        class FieldsExcept
          class MissingKeywordArgumentError < ArgumentError
            # rubocop:todo Layout/LineLength
            MSG = "You must call with `fields` or `keepfields`. `fields` is preferred."
            # rubocop:enable Layout/LineLength
            def initialize(msg = MSG)
              super
            end
          end

          # rubocop:todo Layout/LineLength
          # @param keepfields [Array<Symbol>, Symbol, nil] **DEPRECATED; DO NOT USE**
          # rubocop:enable Layout/LineLength
          # @param fields [Array<Symbol>, Symbol, nil] list of fields to keep
          # rubocop:todo Layout/LineLength
          # @note The `keepfields` parameter will be deprecated in a future version. Use `fields` in new code.
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          # @raise {MissingKeywordArgumentError} if neither `fields` nor `keepfields` is provided
          # rubocop:enable Layout/LineLength
          def initialize(keepfields: nil, fields: nil)
            if keepfields && fields
              # rubocop:todo Layout/LineLength
              puts %(#{Kiba::Extend.warning_label}: Do not use both `keepfields` and `fields`. Defaulting to process using `fields`)
              # rubocop:enable Layout/LineLength
              @fields = [fields].flatten
            elsif keepfields
              # rubocop:todo Layout/LineLength
              puts %(#{Kiba::Extend.warning_label}: The `keepfields` keyword is being deprecated in a future version. Change it to `fields` in your ETL code.)
              # rubocop:enable Layout/LineLength
              @fields = [keepfields].flatten
            elsif fields
              @fields = [fields].flatten
            else
              raise MissingKeywordArgumentError
            end
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            deletefields = row.keys - fields
            deletefields.each { |f| row.delete(f) }
            row
          end

          private

          attr_reader :fields
        end
      end
    end
  end
end
