# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Fingerprint

        # Adds a base64 strict encoded hash to the target field. The value hashed is the values of
        #   the specified fields, joined into a string using the given delimiter
        #
        # @note The `delim` used for this transform must not conflict with your application/project delimiters.
        #   For example, if your `delim` setting (for multivalue fields) is `|`, this `delim` value should not
        #   equal or contain that character. Otherwise, the fingerprint decoder may get confused about what is
        #   a separate field vs. multiple values inside one field, and things will be a mess.
        #
        # # Examples
        #
        # Used in pipeline as:
        #
        # ```
        # transform Fingerprint::Add, fields: %i[b c d e], delim: ';;;', target: :fp
        # ```
        #
        # Input table:
        #
        # ```
        # | a   | b   | c   | d    | e |
        # |-----+-----+-----+------+---|
        # | ant | bee | nil | deer |   |
        # ```
        #
        # Results in:
        #
        # ```
        # | a   | b   | c   | d    | e | fp                               |
        # |-----+-----+-----+------+---+----------------------------------|
        # | ant | bee | nil | deer |   | YmVlOzs7bmlsOzs7ZGVlcjs7O2VtcHR5 |
        # ```
        #
        # Input table:
        #
        # ```
        # | a   | b      | c   | d    | e |
        # |-----+--------+-----+------+---|
        # | ant | be;;;e | nil | deer |   |
        # ```
        #
        # Results in an error because column b contains the fingerprint delimiter. If you tried to decode the
        #   resulting fingerprint, you would get too many columns and loss of data integrity
        # 
        # ## Notes
        # Before field values are joined, the following substitutions are run on all field values:
        #
        # - `''` is converted to the string `'empty'`
        # - `nil` is converted to the string `'nil'`
        #
        class Add
          include Kiba::Extend::Transforms::Helpers

          # @param fields [Array<Symbol>] fields whose values should be used in fingerprint
          # @param delim [String] used to join field values into a hashable string
          # @param target [Symbol] field in which fingerprint hash should inserted
          # @raise [DelimiterCollisionError] if `delim` conflicts with
          #   `Kiba::Extend.delim` or `Kiba::Extend.sgdelim`
          # @raise [DelimiterInValueError] if the value of any field used to generate a fingerprint contains the
          #   fingerprint delimiter
          def initialize(fields:, delim:, target:)
            check_delim(delim)
            @fingerprinter = Kiba::Extend::Utils::FingerprintCreator.new(fields: fields, delim: delim)
            @target = target
            @row_num = 0
          end

          # @private
          def process(row)
            @row_num += 1
            row[target] = get_fingerprint(row)
            row
          end

          private

          attr_reader :fingerprinter, :target

          def check_delim(delim)
            raise Kiba::Extend::Transforms::Fingerprint::DelimiterCollisionError if delim[Kiba::Extend.delim]
            raise Kiba::Extend::Transforms::Fingerprint::DelimiterCollisionError if delim[Kiba::Extend.sgdelim]
            raise Kiba::Extend::Transforms::Fingerprint::DelimiterCollisionError if Kiba::Extend.delim[delim]
            raise Kiba::Extend::Transforms::Fingerprint::DelimiterCollisionError if Kiba::Extend.sgdelim[delim]
          end

          def get_fingerprint(row)
            fingerprinter.call(row)
          rescue Kiba::Extend::Utils::DelimInValueFingerprintError
            msg = "#{Kiba::Extend.warning_label}: Row #{@row_num}: A value in the fields used to create a fingerprint contains the fingerprint delimiter"
            raise Kiba::Extend::Transforms::Fingerprint::DelimiterInValueError, msg
          end
        end
      end
    end
  end
end
