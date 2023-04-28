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
        # @example With `prepend_source_field_name` and `delete_sources` true
        #   # Used in pipeline as:
        #   # transform CombineValues::FullRecord,
        #   #    prepend_source_field_name: true,
        #   #    delete_sources: true
        #   xform = CombineValues::FullRecord.new(
        #     prepend_source_field_name: true,
        #     delete_sources: true
        #   )
        #   input = [
        #     {name: "Weddy", sex: "m", source: "adopted"},
        #     {name: "Keet", sex: nil, source: "hatched"},
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {index: "name: Weddy sex: m source: adopted"},
        #     {index: "name: Keet source: hatched"}
        #   ]
        #   expect(result).to eq(expected)
        class FullRecord < FromFieldsWithDelimiter
          # @param target [Symbol] Field into which the combined value will be
          #   written. May be one of the source fields
          # @param sep [String] Will be deprecated in a future version. Do not
          #   use.
          # @param delim [String] Value used to separate individual field values
          #   in combined target field
          # @param prepend_source_field_name [Boolean] Whether to insert the
          #   source field name before its value in the combined value.
          # @param delete_sources [Boolean] Whether to delete the source fields
          #   after combining their values into the target field. If target
          #   field name is the same as one of the source fields, the target
          #   field is not deleted.
          def initialize(target: :index, sep: nil, delim: nil,
                         prepend_source_field_name: false,
                         delete_sources: false)
            super
          end
        end
      end
    end
  end
end
