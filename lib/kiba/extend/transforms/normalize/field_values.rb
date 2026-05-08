# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Normalize
        # Apply Kiba::Extend::Utils::StringNormalizer to the values in the
        #   indicated fields
        #
        # @note The basic functionality of Kiba::Extend::Utils::StringNormalizer
        #   is described and tested in that class
        #
        # @example Single values
        #   # Used in pipeline as:
        #   # transform Normalize::FieldValues,
        #   #   fields: %i[animal name],
        #   #   replacements: {
        #   #     "e" => "E",
        #   #     /a$/ => "aaaa"
        #   #   },
        #   #   xforms: [:blank, ->(str) { str.reverse }]
        #
        #   xform = Normalize::FieldValues.new(
        #     fields: %i[animal name],
        #     replacements: {
        #       "e" => "E",
        #       /a$/ => "aaaa"
        #     },
        #     xforms: [:blank, ->(str) { str.reverse }]
        #   )
        #   input = [
        #     {animal: "guinea", name: "Napo"},
        #     {animal: "", name: nil}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {animal: "aaaaEniug", name: "opaN"},
        #     {animal: "", name: nil}
        #   ]
        #   expect(result).to eq(expected)
        # @example Multi-values
        #   # Used in pipeline as:
        #   # transform Normalize::FieldValues,
        #   #   fields: %i[animal name],
        #   #   delim: "|",
        #   #   replacements: {
        #   #     "e" => "E",
        #   #     /a$/ => "aaaa"
        #   #   },
        #   #   xforms: [:blank, ->(str) { str.reverse }]
        #
        #   xform = Normalize::FieldValues.new(
        #     fields: %i[animal name],
        #     delim: "|",
        #     replacements: {
        #       "e" => "E",
        #       /a$/ => "aaaa"
        #     },
        #     xforms: [:blank, ->(str) { str.reverse }]
        #   )
        #   input = [
        #     {animal: "guinea", name: "Napo|Earhart"},
        #     {animal: "", name: nil}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {animal: "aaaaEniug", name: "opaN|trahraE"},
        #     {animal: "", name: nil}
        #   ]
        #   expect(result).to eq(expected)
        # @example Targets
        #   # Used in pipeline as:
        #   # transform Normalize::FieldValues,
        #   #   fields: %i[animal name],
        #   #   targets: %i[a b],
        #   #   replacements: {
        #   #     "e" => "E",
        #   #     /a$/ => "aaaa"
        #   #   },
        #   #   xforms: [:blank, ->(str) { str.reverse }]
        #
        #   xform = Normalize::FieldValues.new(
        #     fields: %i[animal name],
        #     targets: %i[a b],
        #     replacements: {
        #       "e" => "E",
        #       /a$/ => "aaaa"
        #     },
        #     xforms: [:blank, ->(str) { str.reverse }]
        #   )
        #   input = [
        #     {animal: "guinea", name: "Napo"},
        #     {animal: "", name: nil}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {animal: "guinea", name: "Napo", a: "aaaaEniug", b: "opaN"},
        #     {animal: "", name: nil, a: "", b: nil}
        #   ]
        #   expect(result).to eq(expected)
        class FieldValues
          # (see Kiba::Extend::Utils::StringNormalizer#initialize)
          # @param fields [Array<Symbol>, Symbol] field name or list of field
          #   names to add
          # @param targets [NilValue, Array<Symbol>, Symbol] field name or list
          #   of field names in which to write normalized values; **Must have
          #   same number of elements as `fields`**
          # @param delim [nilValue, String] when non-nil, each value will be
          #   split into multi-values using this string prior to
          #   normalization
          def initialize(fields:, targets: nil, delim: nil, mode: nil,
            replacements: {}, xforms: [])
            @fields = [fields].flatten
            @targets = if targets
              targetarr = [targets].flatten
              unless @fields.length == targetarr.length
                fail(Kiba::Extend::UnbalancedFieldsTargetsError)
              end
              targetarr
            end

            @delim = delim
            @normalizer = Kiba::Extend::Utils::StringNormalizer.new(
              mode: mode,
              replacements: replacements,
              xforms: xforms
            )
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            fields.each_with_index do |field, idx|
              normalize_field_value(row, field, idx)
            end

            row
          end

          private

          attr_reader :fields, :targets, :delim, :normalizer

          def normalize_field_value(row, field, idx)
            val = row[field]
            return row if val.blank? && !targets

            target = targets ? targets[idx] : field
            if val.blank? && targets
              row[target] = val
              return row
            end

            vals = delim ? val.split(delim) : [val]
            row[target] = vals.map { |v| normalizer.call(v) }
              .join(delim)
            row
          end
        end
      end
    end
  end
end
