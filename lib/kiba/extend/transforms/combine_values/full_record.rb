# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module CombineValues
        # Concatenates values of all fields in each record together into the
        #   target field, using the given string as value separator in the
        #   combined value
        #
        # @example With defaults
        #   # Used in pipeline as:
        #   # transform CombineValues::FullRecord
        #   xform = CombineValues::FullRecord.new
        #   input = [
        #     {name: "Weddy", sex: "m", source: "adopted"},
        #     {source: "hatched", sex: "f", name: "Niblet"},
        #     {source: "", sex: "m", name: "Tiresias"},
        #     {name: "Keet", sex: nil, source: "hatched"},
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {name: "Weddy", sex: "m", source: "adopted",
        #       index: "Weddy m adopted"},
        #     {source: "hatched", sex: "f", name: "Niblet", index:
        #       "Niblet f hatched"},
        #     {source: "", sex: "m", name: "Tiresias", index: "Tiresias m"},
        #     {name: "Keet", sex: nil, source: "hatched", index: 'Keet hatched'}
        #   ]
        #   expect(result).to eq(expected)
        # @example With custom target and delim
        #   # Used in pipeline as:
        #   # transform CombineValues::FullRecord, target: :all, delim: "."
        #   xform = CombineValues::FullRecord.new(
        #     target: :all,
        #     delim: "."
        #   )
        #   input = [
        #     {name: "Weddy", sex: "m", source: "adopted"},
        #     {source: "hatched", sex: "f", name: "Niblet"},
        #     {source: "", sex: "m", name: "Tiresias"},
        #     {name: "Keet", sex: nil, source: "hatched"},
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {name: "Weddy", sex: "m", source: "adopted",
        #       all: "Weddy.m.adopted"},
        #     {source: "hatched", sex: "f", name: "Niblet", all:
        #       "Niblet.f.hatched"},
        #     {source: "", sex: "m", name: "Tiresias", all: "Tiresias.m"},
        #     {name: "Keet", sex: nil, source: "hatched", all: 'Keet.hatched'}
        #   ]
        #   expect(result).to eq(expected)
        class FullRecord
          include SepDeprecatable

          # @param target [Symbol] Field into which to write full record
          # @param sep [String] Will be deprecated in a future version. Do not
          #   use.
          # @param delim [String] Value used to separate individual field values
          #   in combined target field
          def initialize(target: :index, sep: nil, delim: nil)
            @target = target
            @delim = usedelim(
              sepval: sep,
              delimval: delim,
              calledby: self,
              default: " "
            )
            @fields = nil
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            set_fields(row) unless fields

            vals = fields.map { |field| row[field] }
              .reject(&:blank?)

            row[target] = if vals.empty?
                             nil
                           else
                             vals.join(delim)
                           end
            row
          end

          private

          attr_reader :target, :delim, :fields

          def set_fields(row)
            @fields = row.keys
          end
        end
      end
    end
  end
end
