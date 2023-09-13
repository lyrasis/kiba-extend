# frozen_string_literal: true

# rubocop:todo Layout/LineLength

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
        # ~~~
        # | a | b | c |
        # |---+---+---|
        # | 1 | 2 | 3 |
        # ~~~
        #
        # Used in pipeline as:
        #
        # ~~~
        # transform Delete::FieldsExcept, fields: %i[a c]
        # ~~~
        #
        # Results in:
        #
        # ~~~
        # | a | c |
        # |---+---|
        # | 1 | 3 |
        # ~~~
        #
        # Used in pipeline as:
        #
        # ~~~
        # transform Delete::FieldsExcept, fields: :b
        # ~~~
        #
        # Results in:
        #
        # ~~~
        # | b |
        # |---|
        # | 2 |
        # ~~~
        #
        class FieldsExcept
          class MissingKeywordArgumentError < ArgumentError
            MSG = "You must call with `fields` or `keepfields`. `fields` is preferred."
            def initialize(msg = MSG)
              super
            end
          end

          # @param keepfields [Array<Symbol>, Symbol, nil] **DEPRECATED; DO NOT USE**
          # @param fields [Array<Symbol>, Symbol, nil] list of fields to keep
          # @note The `keepfields` parameter will be deprecated in a future version. Use `fields` in new code.
          # @raise {MissingKeywordArgumentError} if neither `fields` nor `keepfields` is provided
          def initialize(keepfields: nil, fields: nil)
            if keepfields && fields
              puts %(#{Kiba::Extend.warning_label}: Do not use both `keepfields` and `fields`. Defaulting to process using `fields`)
              @fields = [fields].flatten
            elsif keepfields
              puts %(#{Kiba::Extend.warning_label}: The `keepfields` keyword is being deprecated in a future version. Change it to `fields` in your ETL code.)
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
# rubocop:enable Layout/LineLength
