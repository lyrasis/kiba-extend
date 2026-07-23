# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Replace
        # Looks up value of `source` field in given `mapping` Hash. Replaces
        #   orignal value with the result.
        #
        # Optional: put result in new `target` field; look up multiple values
        #   from a multivalue source field, provide a fallback value if source
        #   value is not found in mapping
        #
        # @example In place, deleting source, no delim
        #   # Used in pipeline as:
        #   # transform Replace::FieldValueWithStaticMapping,
        #   #   source: :color,
        #   #   mapping: {
        #   #     "cb" => "coral blue",
        #   #     "rp" => "royal purple",
        #   #     "p" => "pied pearl",
        #   #     "pl" => "pearl gray",
        #   #     nil => "undetermined"
        #   #   }
        #   xform = Replace::FieldValueWithStaticMapping.new(
        #     source: :color,
        #     mapping: {
        #       "cb" => "coral blue",
        #       "rp" => "royal purple",
        #       "p" => "pied",
        #       "pl" => "pearl gray",
        #       nil => "undetermined"
        #     }
        #   )
        #   input = [
        #     {name: "Lazarus", color: "cb"},
        #     {name: "Inkpot", color: "rp"},
        #     {name: "Zipper", color: "rp|p"},
        #     {name: "New", color: nil},
        #     {name: "Old", color: ""}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {name: "Lazarus", color: "coral blue"},
        #     {name: "Inkpot", color: "royal purple"},
        #     {name: "Zipper", color: "rp|p"},
        #     {name: "New", color: "undetermined"},
        #     {name: "Old", color: ""}
        #   ]
        #   expect(result).to eq(expected)
        # @example In place, deleting source, with delim
        #   # Used in pipeline as:
        #   # transform Replace::FieldValueWithStaticMapping,
        #   #   source: :color,
        #   #   mapping: {
        #   #     "cb" => "coral blue",
        #   #     "rp" => "royal purple",
        #   #     "p" => "pied pearl",
        #   #     "pl" => "pearl gray",
        #   #     nil => "undetermined"
        #   #   },
        #   #   delim: "|"
        #   xform = Replace::FieldValueWithStaticMapping.new(
        #     source: :color,
        #     mapping: {
        #       "cb" => "coral blue",
        #       "rp" => "royal purple",
        #       "p" => "pied",
        #       "pl" => "pearl gray",
        #       nil => "undetermined"
        #     },
        #     delim: "|"
        #   )
        #   input = [
        #     {name: "Zipper", color: "rp|p"},
        #     {name: "Divebomber|Earlybird", color: "pl|pl"},
        #     {name: "Clover|Hops", color: "rp|c"},
        #     {name: "New|Hunter", color: "|pl"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {name: "Zipper", color: "royal purple|pied"},
        #     {name: "Divebomber|Earlybird", color: "pearl gray|pearl gray"},
        #     {name: "Clover|Hops", color: "royal purple|c"},
        #     {name: "New|Hunter", color: "|pearl gray"}
        #   ]
        #   expect(result).to eq(expected)
        # @example No mapping for value, fallback_val = :nil
        #   # Used in pipeline as:
        #   # transform Replace::FieldValueWithStaticMapping,
        #   #   source: :color,
        #   #   mapping: {
        #   #     "cb" => "coral blue",
        #   #     "rp" => "royal purple",
        #   #     "p" => "pied pearl",
        #   #     "pl" => "pearl gray",
        #   #     nil => "undetermined"
        #   #   },
        #   #   delim: "|",
        #   #   fallback_val: :nil
        #   xform = Replace::FieldValueWithStaticMapping.new(
        #     source: :color,
        #     mapping: {
        #       "cb" => "coral blue",
        #       "rp" => "royal purple",
        #       "p" => "pied",
        #       "pl" => "pearl gray",
        #       nil => "undetermined"
        #     },
        #     delim: "|",
        #     fallback_val: :nil
        #   )
        #   input = [
        #     {name: "Vern", color: "v"},
        #     {name: "Clover|Hops", color: "rp|c"},
        #     {name: "New", color: nil},
        #     {name: "Old", color: ""},
        #     {name: "New|Hunter", color: "|pl"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {name: "Vern", color: nil},
        #     {name: "Clover|Hops", color: "royal purple|"},
        #     {name: "New", color: "undetermined"},
        #     {name: "Old", color: nil},
        #     {name: "New|Hunter", color: "|pearl gray"}
        #   ]
        #   expect(result).to eq(expected)
        # @example No mapping for value, fallback_val = "nope"
        #   # Used in pipeline as:
        #   # transform Replace::FieldValueWithStaticMapping,
        #   #   source: :color,
        #   #   mapping: {
        #   #     "cb" => "coral blue",
        #   #     "rp" => "royal purple",
        #   #     "p" => "pied pearl",
        #   #     "pl" => "pearl gray",
        #   #     nil => "undetermined"
        #   #   },
        #   #   delim: "|",
        #   #   fallback_val: "nope"
        #   xform = Replace::FieldValueWithStaticMapping.new(
        #     source: :color,
        #     mapping: {
        #       "cb" => "coral blue",
        #       "rp" => "royal purple",
        #       "p" => "pied",
        #       "pl" => "pearl gray",
        #       nil => "undetermined"
        #     },
        #     delim: "|",
        #     fallback_val: "nope"
        #   )
        #   input = [
        #     {name: "Vern", color: "v"},
        #     {name: "Clover|Hops", color: "rp|c"},
        #     {name: "New", color: nil},
        #     {name: "Old", color: ""},
        #     {name: "New|Hunter", color: "|pl"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {name: "Vern", color: "nope"},
        #     {name: "Clover|Hops", color: "royal purple|nope"},
        #     {name: "New", color: "undetermined"},
        #     {name: "Old", color: "nope"},
        #     {name: "New|Hunter", color: "nope|pearl gray"}
        #   ]
        #   expect(result).to eq(expected)
        # @example With target, deleting source
        #   # Used in pipeline as:
        #   # transform Replace::FieldValueWithStaticMapping,
        #   #   source: :color,
        #   #   target: :fullcol,
        #   #   mapping: {"cb" => "coral blue"}
        #   xform = Replace::FieldValueWithStaticMapping.new(
        #     source: :color,
        #     target: :fullcol,
        #     mapping: {"cb" => "coral blue"}
        #   )
        #   input = [
        #     {name: "Lazarus", color: "cb"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {name: "Lazarus", fullcol: "coral blue"}
        #   ]
        #   expect(result).to eq(expected)
        # @example With target, not deleting source
        #   # Used in pipeline as:
        #   # transform Replace::FieldValueWithStaticMapping,
        #   #   source: :color,
        #   #   target: :fullcol,
        #   #   mapping: {"cb" => "coral blue"},
        #   #   delete_source: false
        #   xform = Replace::FieldValueWithStaticMapping.new(
        #     source: :color,
        #     target: :fullcol,
        #     mapping: {"cb" => "coral blue"},
        #     delete_source: false
        #   )
        #   input = [
        #     {name: "Lazarus", color: "cb"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {name: "Lazarus", color: "cb", fullcol: "coral blue"}
        #   ]
        #   expect(result).to eq(expected)
        class FieldValueWithStaticMapping
          # @param source [Symbol] the field containing the value to look up
          #   for mapping
          # @param target [nil, Symbol] optional new field in which to put the
          #   mapped/looked up result
          # @param mapping [Hash] keys = source field values
          # @param fallback_val [:orig, :nil, String] value to use if no match
          #   for source value is found in mapping
          # @param delete_source [Boolean] whether to remove source field after
          #   mapping. Has no effect if a different target field is not given
          # @param delim [nil, String] if a value is given, turns on "multival"
          #   mode, splitting the whole field value on the string given
          #   (since 3.0.0)
          def initialize(source:, mapping:, target: nil, fallback_val: :orig,
            delete_source: true, delim: nil)
            @source = source
            @target = target || source
            @mapping = mapping
            @fallback = fallback_val
            @del = delete_source
            @delim = delim
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            set_initial_value(row)
            rowval = row[source]
            vals = prep_vals(rowval)

            @fallback_val = get_fallback_vals(vals)

            row[target] = join_result(result(vals))

            row.delete(source) if source != target && del
            row
          end

          private

          attr_reader :source, :target, :mapping, :fallback, :del, :delim,
            :fallback_val

          def get_fallback_val(source_val)
            case fallback
            when :orig
              source_val
            when :nil
              nil
            else
              fallback
            end
          end

          def get_fallback_vals(source_vals)
            source_vals.map { |val| get_fallback_val(val) }
          end

          def join_result(results)
            return nil if results.length == 1 && results.first.nil?

            delim ? results.join(delim) : results.first
          end

          def result(vals)
            vals.map.with_index { |v, i| mapping.fetch(v, fallback_val[i]) }
          end

          def prep_vals(val)
            return [nil] if val.nil?
            return [""] if val.empty?

            delim ? val.split(delim, -1) : [val]
          end

          def set_initial_value(row)
            return if source == target

            row[target] = nil
          end
        end
      end
    end
  end
end
