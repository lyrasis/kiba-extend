# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Deduplicate
        # Removes the value(s) of `source` from `targets`
        #
        # @example Multival, case sensitive, with sep
        #   # Used in pipeline as:
        #   # transform Deduplicate::Fields,
        #   #   source: :x,
        #   #   targets: %i[y z],
        #   #   multival: true,
        #   #   sep: ";"
        #   xform = Deduplicate::Fields.new(
        #     source: :x,
        #     targets: %i[y z],
        #     multival: true,
        #     sep: ";"
        #   )
        #   input = [
        #     {x: "a", y: "a", z: "b"},
        #     {x: "a", y: "a", z: "a"},
        #     {x: "a", y: "b;a", z: "a;c"},
        #     {x: "a;b", y: "b;a", z: "a;c"},
        #     {x: "a", y: "aa", z: "bat"},
        #     {x: nil, y: "a", z: nil},
        #     {x: "", y: ";a", z: "b;"},
        #     {x: "a", y: nil, z: nil},
        #     {x: "a", y: "A", z: "a"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {x: "a", y: nil, z: "b"},
        #     {x: "a", y: nil, z: nil},
        #     {x: "a", y: "b", z: "c"},
        #     {x: "a;b", y: nil, z: "c"},
        #     {x: "a", y: "aa", z: "bat"},
        #     {x: nil, y: "a", z: nil},
        #     {x: "", y: "a", z: "b"},
        #     {x: "a", y: nil, z: nil},
        #     {x: "a", y: "A", z: nil}
        #   ]
        #   expect(result).to eq(expected)
        # @example Multival, case insensitive, with sep
        #   # Used in pipeline as:
        #   # transform Deduplicate::Fields,
        #   #   source: :x,
        #   #   targets: %i[y z],
        #   #   multival: true,
        #   #   sep: ";",
        #   #   casesensitive: false
        #   xform = Deduplicate::Fields.new(
        #     source: :x,
        #     targets: %i[y z],
        #     multival: true,
        #     sep: ";",
        #     casesensitive: false
        #   )
        #   input = [
        #     {x: "a", y: "A", z: "a"},
        #     {x: "a", y: "a", z: "B"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {x: "a", y: nil, z: nil},
        #     {x: "a", y: nil, z: "B"}
        #   ]
        #   expect(result).to eq(expected)
        class Fields
          # @param source [Symbol] name of field containing value to remove from
          #   target fields
          # @param targets [Array<Symbol>] names of fields to remove source
          #   value(s) from
          # @param casesensitive [Boolean] whether matching should be case
          #   sensitive
          # @param multival [Boolean] whether to treat as multi-valued
          # @param sep [String] used to split/join multi-val field values
          def initialize(source:, targets:, casesensitive: true,
            multival: false, sep: Kiba::Extend.delim)
            @source = source
            @targets = targets
            @casesensitive = casesensitive
            @multival = multival
            @sep = sep
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            sourceval = row.fetch(@source, nil)
            return row if sourceval.nil?

            targetvals = @targets.map { |target| row.fetch(target, nil) }
            return row if targetvals.compact.empty?

            sourceval = @multival ? sourceval.split(@sep,
              -1).map(&:strip) : [sourceval.strip]
            targetvals = if @multival
              targetvals.map do |val|
                val.split(@sep, -1).map(&:strip)
              end
            else
              targetvals.map { |val| [val.strip] }
            end

            if sourceval.blank?
              targetvals = targetvals.map { |vals| vals.reject(&:blank?) }
            elsif @casesensitive
              targetvals = targetvals.map { |vals| vals - sourceval }
            else
              sourceval = sourceval.map(&:downcase)
              targetvals = targetvals.map do |vals|
                vals.reject do |val|
                  sourceval.include?(val.downcase)
                end
              end
            end

            targetvals = if @multival
              targetvals.map { |vals| vals&.join(@sep) }
            else
              targetvals.map(&:first)
            end
            targetvals = targetvals.map { |val| val.blank? ? nil : val }

            targetvals.each_with_index { |val, i| row[@targets[i]] = val }

            row
          end
        end
      end
    end
  end
end
