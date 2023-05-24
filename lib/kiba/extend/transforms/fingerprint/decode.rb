# frozen_string_literal: true

require 'base64'

module Kiba
  module Extend
    module Transforms
      module Fingerprint

        # Decodes a fingerprint string and expands it into its source fields
        # @since 2.7.1.65
        #
        # See {Kiba::Extend::Transforms::Fingerprint::Add} for how the :fp field in the examples below
        #   was derived.
        #
        # # Examples
        #
        # Input table:
        #
        # ```
        # | a   | b   | c   | d    | e | fp                               |
        # |-----+-----+-----+------+---+----------------------------------|
        # | ant | bee | nil | deer |   | YmVlOzs7bmlsOzs7ZGVlcjs7O2VtcHR5 |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Fingerprint::Decode, fingerprint: :fp, source_fields: %i[b c d e], delim: ';;;', prefix: 'fp'
        # ```
        #
        # Results in:
        #
        # ```
        # | a   | b   | c   | d    | e | fp                               | fp_b | fp_c | fp_d | fp_e |
        # |-----+-----+-----+------+---+----------------------------------+------+------+------+------|
        # | ant | bee | nil | deer |   | YmVlOzs7bmlsOzs7ZGVlcjs7O2VtcHR5 | bee  | nil  | deer |      |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Fingerprint::Decode, fingerprint: :fp, source_fields: %i[b c d e], delim: ';;;', prefix: 'fp', delete_fp: true
        # ```
        #
        # Results in:
        #
        # ```
        # | a   | b   | c   | d    | e | fp_b | fp_c | fp_d | fp_e |
        # |-----+-----+-----+------+---+------+------+------+------|
        # | ant | bee | nil | deer |   | bee  | nil  | deer |      |
        # ```
        #
        class Decode
          # @param fingerprint [Symbol] the name of the field containing fingerprint values
          # @param source_fields [Array<Symbol>] names of fields used to generate the fingerprint
          # @param delim [String] used to join/split fields before hashing/after decoding
          # @param prefix [String] added to the names of the decoded fields added to rows
          # @param delete_fp [Boolean] whether to delete the given fingerprint field
          def initialize(fingerprint:, source_fields:, delim:, prefix:, delete_fp: false)
            @fingerprint = fingerprint
            @source_fields = source_fields
            @delim = delim
            @prefix = prefix
            @delete = delete_fp
            @num_fields = source_fields.length
            @target_fields = source_fields.map{ |field| "#{prefix}_#{field}".to_sym }
            @row_ct = 0
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            @row_ct += 1
            target_fields.each{ |field| row[field] = nil }

            fpval = row.fetch(fingerprint, nil)
            row.delete(fingerprint) if delete
            return row if fpval.blank?

            decoded = decode(fpval)
            parts = split(decoded)
            reconstituted = reconstitute(parts)
            check_length(reconstituted)

            target_fields.each_with_index do |target, idx|
              row[target] = reconstituted[idx]
            end
            row
          end

          private

          attr_reader :fingerprint, :source_fields, :delim, :prefix, :delete, :num_fields, :target_fields

          def decode(fp)
            Base64.strict_decode64(fp)
            .force_encoding("UTF-8")
          end

          def split(decoded)
            decoded.split(delim)
          end

          def reconstitute(parts)
            parts.map{ |val| val == 'nil' ? nil : val }
              .map{ |val| val == 'empty' ? '' : val }
          end
          # @param decoded [Array<String>]
          def check_length(fieldvals)
            result_length = fieldvals.length
            return if result_length == num_fields

            warn("#{Kiba::Extend.warning_label}: ROW #{@row_ct}: Expected #{num_fields} fields from decoded fingerprint. Got #{result_length}")
          end

          def safe_decoded_value(val)
            return val if val.blank?

            val.force_encoding('UTF-8')
          end
        end
      end
    end
  end
end
