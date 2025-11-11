# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Deduplicate
        # Field value deduplication that is at least semi-safe for use with
        #   grouped fields that expect the same number of values for each field
        #   in the grouping
        #
        # @note Tread with caution, as this has not been used much and is not
        #   extensively tested.
        #
        # @example Basic usage/defaults
        #   # Used in pipeline as:
        #   # transform Deduplicate::FieldGroup,
        #   #   grouped_fields: %i[name work role],
        #   #   delim: ';'
        #   xform = Deduplicate::FieldGroup.new(
        #     grouped_fields: %i[name work role],
        #     delim: ';'
        #   )
        #   input = [
        #     # nothing in group
        #     {name: nil,
        #      work: nil,
        #      role: nil},
        #     # single group
        #     {name: "Sue",
        #      work: "Bk",
        #      role: "auth"},
        #     # nil grouped field
        #     {name: "Sue;Sue;Sue",
        #      work: nil,
        #      role: "auth;ed;auth"},
        #     # nil value in other field
        #     {name: "Sue;Jill;Joan;Jill",
        #      work: "Bk;;Bk;",
        #      role: "auth;auth;ed;auth"},
        #     # work is empty string value; role has only 2 values
        #     {name: "Cam;Jan;Cam",
        #      work: "",
        #      role: "auth;ed"},
        #     # lots of values, multiple duplicates
        #     {name: "Fred;Jan;Fred;Bob;Fred;Bob",
        #      work: "Rpt;Bk;Paper;Bk;Rpt;Bk",
        #      role: "auth;photog;ed;ill;auth;ed."}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     # nothing in group
        #     {name: nil,
        #      work: nil,
        #      role: nil},
        #     # single group
        #     {name: "Sue",
        #      work: "Bk",
        #      role: "auth"},
        #     # nil grouped field
        #     {name: "Sue;Sue",
        #      work: nil,
        #      role: "auth;ed"},
        #     # nil value in other field
        #     {name: "Sue;Jill;Joan",
        #      work: "Bk;;Bk",
        #      role: "auth;auth;ed"},
        #     # work is empty string value; role has only 2 values
        #     {name: "Cam;Jan;Cam",
        #      work: "",
        #      role: "auth;ed"},
        #     # lots of values, multiple duplicates
        #     {name: "Fred;Jan;Fred;Bob;Bob",
        #      work: "Rpt;Bk;Paper;Bk;Bk",
        #      role: "auth;photog;ed;ill;ed."}
        #   ]
        #   expect(result).to eq(expected)
        # @example Case insensitive deduplication
        #   xform = Deduplicate::FieldGroup.new(
        #     grouped_fields: %i[name role],
        #     delim: ';',
        #     ignore_case: true
        #   )
        #   input = [
        #     {name: 'Jan;jan',
        #      role: 'auth;Auth'},
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {name: 'Jan',
        #      role: 'auth'},
        #   ]
        #   expect(result).to eq(expected)
        # @example Normalized deduplication
        #   xform = Deduplicate::FieldGroup.new(
        #     grouped_fields: %i[name role],
        #     delim: ';',
        #     normalized: true
        #   )
        #   input = [
        #     {name: 'Jan;Jan.;Sam;Sam?;Hops',
        #      role: 'auth./ill.;auth, ill;ed;ed.;Ed.'},
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {name: 'Jan;Sam;Hops',
        #      role: 'auth./ill.;ed;Ed.'},
        #   ]
        #   expect(result).to eq(expected)
        class FieldGroup
          # @param grouped_fields [Array<Symbol>] fields in the
          #   multi-field grouping to be deduplicated.
          # @param delim [nil, String] used to split/join multivalued field
          #   values
          # @param ignore_case [Boolean]
          # @param normalized [Boolean] if true, will apply
          #   {Kiba::Extend::Utils::StringNormalizer} with arguments:
          #   `mode: :plain, downcased: false` to values for comparison
          def initialize(grouped_fields: [], delim: Kiba::Extend.delim,
            ignore_case: false, normalized: false)
            @fields = grouped_fields
            @delim = delim
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: grouped_fields
            )
            @ignore_case = ignore_case
            if normalized
              @normalizer = Utils::StringNormalizer.new(downcased: false)
            end
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            vals = getter.call(row)
            return row if vals.empty?
            return row if vals.values.none? { |v| v.match?(delim) }

            vals.transform_values! do |v|
              v.split(delim).map { |v| v.empty? ? nil : v }
            end

            keep = indexes_to_keep(vals)
            deduplicate(vals, keep).each do |field, vals|
              row[field] = vals.join(delim)
            end

            row
          end

          private

          attr_reader :fields, :delim, :getter, :ignore_case, :normalizer

          def indexes_to_keep(vals)
            build_comparable(vals).to_a
              .uniq { |arr| arr[1] }
              .map { |arr| arr[0] }
              .flatten
          end

          def deduplicate(vals, keep)
            vals.clone.transform_values! do |arr|
              arr.select.with_index { |v, i| keep.include?(i) }
            end
          end

          def build_comparable(vals)
            cvals = vals.dup.transform_values! { |v| v.dup }
            if ignore_case
              cvals.transform_values! { |vs| vs.map { |v| v.downcase } }
            end
            if normalizer
              cvals.transform_values! do |vs|
                vs.map { |v| normalizer.call(v) }
              end
            end

            acc = {}
            ct = 0
            until cvals.values.all? { |arr| arr.empty? }
              acc[ct] = cvals.values.map { |arr| arr.shift }
              ct += 1
            end
            acc
          end
        end
      end
    end
  end
end
