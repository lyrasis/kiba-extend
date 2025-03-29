# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Fingerprint
        # Decodes a fingerprint string and compares each decoded field value to
        #   the value in the main field. Records the field name for each value
        #   with changes in the target field. If all decoded fields match their
        #   main fields, the target field is left blank.
        #
        # See {Decode} for details on the decoding process.
        #
        # ## Notes on examples
        # ### Example 1
        # - Row 1: fingerprinted values didn't change
        # - Row 2: :b changed from bee to bees, and :d changed from deer to doe
        #   after fingerprint was encoded. :e was changed from nil to an empty
        #   string, but because :empty_equals_nil is true by default, this
        #   change is not reported
        # - Row 3: :d was removed after fingerprint was encoded.
        #
        # ### Example 2
        # - Shows how Row 2 from Example 1 is treated differently if
        #   :empty_equals_nil is set to false
        #
        # ### Example 3
        # - Shows how Row 3 from Example 1 is treated differently if we indicate
        #   that :d should be ignored
        #
        # @example 1: With defaults
        #   # Used in pipeline as:
        #   # transform Fingerprint::FlagChanged,
        #   #   fingerprint: :fp,
        #   #   source_fields: %i[b c d e],
        #   #   delim: ';;;',
        #   #   target: :changed
        #   xform = Fingerprint::FlagChanged.new(
        #     fingerprint: :fp,
        #     source_fields: %i[b c d e],
        #     delim: ';;;',
        #     target: :changed
        #   )
        #   input = [
        #     {a: 'ant', b: 'bee', c: nil, d: 'deer', e: nil,
        #      fp: 'YmVlOzs7bmlsOzs7ZGVlcjs7O2VtcHR5'},
        #     {a: 'ant', b: 'bees', c: nil, d: 'doe', e: '',
        #      fp: 'YmVlOzs7bmlsOzs7ZGVlcjs7O2VtcHR5'},
        #     {a: 'ant', b: 'bee', c: nil, e: '',
        #      fp: 'YmVlOzs7bmlsOzs7ZGVlcjs7O2VtcHR5'}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {a: 'ant', b: 'bee', c: nil, d: 'deer', e: nil,
        #      fp: 'YmVlOzs7bmlsOzs7ZGVlcjs7O2VtcHR5',
        #      fp_b: 'bee', fp_c: nil, fp_d: 'deer', fp_e: '',
        #      changed: nil},
        #      {a: 'ant', b: 'bees', c: nil, d: 'doe', e: '',
        #      fp: 'YmVlOzs7bmlsOzs7ZGVlcjs7O2VtcHR5',
        #      fp_b: 'bee', fp_c: nil, fp_d: 'deer', fp_e: '',
        #      changed: "b|d"},
        #      {a: 'ant', b: 'bee', c: nil, e: '',
        #      fp: 'YmVlOzs7bmlsOzs7ZGVlcjs7O2VtcHR5',
        #      fp_b: 'bee', fp_c: nil, fp_d: 'deer', fp_e: '',
        #      changed: "d"}
        #   ]
        #   expect(result).to eq(expected)
        # @example 2: With :empty_equals_nil false
        #   # Used in pipeline as:
        #   # transform Fingerprint::FlagChanged,
        #   #   fingerprint: :fp,
        #   #   source_fields: %i[b c d e],
        #   #   delim: ';;;',
        #   #   target: :changed,
        #   #   empty_equals_nil: false
        #   xform = Fingerprint::FlagChanged.new(
        #     fingerprint: :fp,
        #     source_fields: %i[b c d e],
        #     delim: ';;;',
        #     target: :changed,
        #     empty_equals_nil: false
        #   )
        #   input = [
        #     {a: 'ant', b: 'bee', c: nil, d: 'deer', e: nil,
        #      fp: 'YmVlOzs7bmlsOzs7ZGVlcjs7O2VtcHR5'}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {a: 'ant', b: 'bee', c: nil, d: 'deer', e: nil,
        #      fp: 'YmVlOzs7bmlsOzs7ZGVlcjs7O2VtcHR5',
        #      fp_b: 'bee', fp_c: nil, fp_d: 'deer', fp_e: '',
        #      changed: "e"}
        #   ]
        #   expect(result).to eq(expected)
        # @example 3: With ignore_fields
        #   # Used in pipeline as:
        #   # transform Fingerprint::FlagChanged,
        #   #   fingerprint: :fp,
        #   #   source_fields: %i[b c d e],
        #   #   delim: ';;;',
        #   #   target: :changed,
        #   #   ignore_fields: :d
        #   xform = Fingerprint::FlagChanged.new(
        #     fingerprint: :fp,
        #     source_fields: %i[b c d e],
        #     delim: ';;;',
        #     target: :changed,
        #     ignore_fields: :d
        #   )
        #   input = [
        #     {a: 'ant', b: 'bee', c: nil, e: '',
        #      fp: 'YmVlOzs7bmlsOzs7ZGVlcjs7O2VtcHR5'}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #      {a: 'ant', b: 'bee', c: nil, e: '',
        #      fp: 'YmVlOzs7bmlsOzs7ZGVlcjs7O2VtcHR5',
        #      fp_b: 'bee', fp_c: nil, fp_d: 'deer', fp_e: '',
        #      changed: nil}
        #   ]
        #   expect(result).to eq(expected)
        class FlagChanged
          # @param fingerprint [Symbol] the name of the field containing
          #   fingerprint values
          # @param source_fields [Array<Symbol>] names of fields used to
          #   generate the fingerprint
          # @param target [Symbol] name of field in which to add field names
          #   in which values have changed
          # @param delim [String] used to join/split fields before hashing/after
          #   decoding. The default value is U+241F / E2 90 9F / Symbol for Unit
          #   Separator.
          # @param prefix [String] added to the names of the decoded fields
          #   added to rows
          # @param delete_fp [Boolean] whether to delete the given fingerprint
          #   field
          # @param ignore_fields [Symbol, Array<Symbol>] fields included in the
          #   fingerprint that should NOT compared/flagged
          # @param empty_equals_nil [Boolean] whether to treat blank and nil
          #   values as equal
          #
          # @since 4.0.0
          def initialize(fingerprint:, source_fields:, target:, delim: "␟",
            prefix: "fp", delete_fp: false, ignore_fields: [],
            empty_equals_nil: true)
            @decoder = Decode.new(
              fingerprint: fingerprint,
              source_fields: source_fields,
              delim: delim,
              prefix: prefix,
              delete_fp: delete_fp
            )
            @target = target
            @empty_equals_nil = empty_equals_nil
            @source_fields = source_fields - [ignore_fields].flatten
            @target_fields = @source_fields.map do |field|
              :"#{prefix}_#{field}"
            end
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            row[target] = nil
            decoder.process(row)
            changed = record_changes(row)
            return row if changed.empty?

            row[target] = changed.join(Kiba::Extend.delim)
            row
          end

          private

          attr_reader :decoder, :target, :empty_equals_nil, :source_fields,
            :target_fields

          def record_changes(row)
            source_fields.map.with_index do |field, idx|
              field_unchanged?(row, field, idx) ? nil : field
            end
              .compact
          end

          def field_unchanged?(row, field, idx)
            return true if empty_equals_nil && both_blank?(row, field, idx)

            row[field] == row[target_fields[idx]]
          end

          def both_blank?(row, field, idx)
            is_blank?(row[field]) && is_blank?(row[target_fields[idx]])
          end

          def is_blank?(val)
            val.nil? || val.empty?
          end
        end
      end
    end
  end
end
