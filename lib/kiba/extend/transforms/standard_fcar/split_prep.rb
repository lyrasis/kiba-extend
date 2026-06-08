# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module StandardFcar
        # rubocop:disable Layout/LineLength

        # Prepares data in the given `:orig` field for input to split
        #   FCAR process. Applies the indicated splits to the orig
        #   field, writing the results to `:split_val` field; adds
        #   `:sort`, `:autosplit`, and `:prepped_row_fingerprint`
        #   fields.
        # @example With Array of splitters
        #   # Used in pipeline as:
        #   # transform StandardFcar::SplitPrep,
        #   #   splitters: [",", ";"],
        #   #   orig: :val
        #
        #   xform = StandardFcar::SplitPrep.new(
        #      splitters: [",", ";"],
        #      orig: :val
        #   )
        #   input = [
        #     {val: "a"},
        #     {val: "b, c"},
        #     {val: "d;e"},
        #     {val: "f,g;h"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {split_val: "a", orig: "a", autosplit: "n", sort: "a 000",
        #       prepped_row_fingerprint: "YeKQn2HikJ9hIDAwMA=="},
        #     {split_val: "b", orig: "b, c", autosplit: "y", sort: "b, c 000",
        #       prepped_row_fingerprint: "YiwgY+KQn2LikJ9iLCBjIDAwMA=="},
        #     {split_val: "c", orig: "b, c", autosplit: "y", sort: "b, c 001",
        #       prepped_row_fingerprint: "YiwgY+KQn2PikJ9iLCBjIDAwMQ=="},
        #     {split_val: "d", orig: "d;e", autosplit: "y", sort: "d;e 000",
        #       prepped_row_fingerprint: "ZDtl4pCfZOKQn2Q7ZSAwMDA="},
        #     {split_val: "e", orig: "d;e", autosplit: "y", sort: "d;e 001",
        #       prepped_row_fingerprint: "ZDtl4pCfZeKQn2Q7ZSAwMDE="},
        #     {split_val: "f", orig: "f,g;h", autosplit: "y", sort: "f,g;h 000",
        #       prepped_row_fingerprint: "ZixnO2jikJ9m4pCfZixnO2ggMDAw"},
        #     {split_val: "g", orig: "f,g;h", autosplit: "y", sort: "f,g;h 001",
        #       prepped_row_fingerprint: "ZixnO2jikJ9n4pCfZixnO2ggMDAx"},
        #     {split_val: "h", orig: "f,g;h", autosplit: "y", sort: "f,g;h 002",
        #       prepped_row_fingerprint: "ZixnO2jikJ9o4pCfZixnO2ggMDAy"}
        #   ]
        #   expect(result).to eq(expected)
        # @example With Hash of splitters
        #   # Used in pipeline as:
        #   # transform StandardFcar::SplitPrep,
        #   #   splitters: {"," => "comma", ";" => "semicolon"},
        #   #   orig: :val
        #
        #   xform = StandardFcar::SplitPrep.new(
        #      splitters: {"," => "comma", ";" => "semicolon"},
        #      orig: :val
        #   )
        #   input = [
        #     {val: "a"},
        #     {val: "b, c"},
        #     {val: "d;e"},
        #     {val: "f,g;h"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {split_val: "a", orig: "a", autosplit: nil, sort: "a 000",
        #       prepped_row_fingerprint: "YeKQn2HikJ9hIDAwMA=="},
        #     {split_val: "b", orig: "b, c", autosplit: "comma", sort: "b, c 000",
        #       prepped_row_fingerprint: "YiwgY+KQn2LikJ9iLCBjIDAwMA=="},
        #     {split_val: "c", orig: "b, c", autosplit: "comma", sort: "b, c 001",
        #       prepped_row_fingerprint: "YiwgY+KQn2PikJ9iLCBjIDAwMQ=="},
        #     {split_val: "d", orig: "d;e", autosplit: "semicolon", sort: "d;e 000",
        #       prepped_row_fingerprint: "ZDtl4pCfZOKQn2Q7ZSAwMDA="},
        #     {split_val: "e", orig: "d;e", autosplit: "semicolon", sort: "d;e 001",
        #       prepped_row_fingerprint: "ZDtl4pCfZeKQn2Q7ZSAwMDE="},
        #     {split_val: "f", orig: "f,g;h", autosplit: "comma|semicolon", sort: "f,g;h 000",
        #       prepped_row_fingerprint: "ZixnO2jikJ9m4pCfZixnO2ggMDAw"},
        #     {split_val: "g", orig: "f,g;h", autosplit: "comma|semicolon", sort: "f,g;h 001",
        #       prepped_row_fingerprint: "ZixnO2jikJ9n4pCfZixnO2ggMDAx"},
        #     {split_val: "h", orig: "f,g;h", autosplit: "comma|semicolon", sort: "f,g;h 002",
        #       prepped_row_fingerprint: "ZixnO2jikJ9o4pCfZixnO2ggMDAy"}
        #   ]
        #   expect(result).to eq(expected)
        class SplitPrep
          # rubocop:enable Layout/LineLength

          # Used internally to indicate the places
          #   where the value needs to be split, before splitting is
          #   actually applied. The U+241F / E2 90 9F / Symbol for Unit
          #   Separator is used to avoid clashes with other common delimiter
          #   strings that may be present in values
          # @return [String] U+241F / E2 90 9F / Symbol for Unit Separator
          UNIT_SEP = "␟"

          # @param splitters [Array<String, Regexp>,
          #   Hash{String, Regexp => String, Symbol}] Values on which to
          #   split the :orig column value. If given an Array, :autosplit column
          #   will be populated with "y" or "n". If given a Hash, the Hash keys
          #   are used as the splitters, and the :autosplit column will be
          #   populated with the joined Hash values of the splitters that were
          #   applied
          # @param orig [Symbol] field containing values that will be
          #   programmatically split and reviewed by client in FCAR process
          # @param target [Symbol] field in which the results of programmatic
          #   splitting will be written, and client can make corrections
          # @param sort [Symbol] field in which the sort values will be written
          # @param indicator [Symbol] field in which inidication of whether
          #   splitting was applied to target values will be written
          # @param fingerprint [Symbol] field in which prepped row identifying
          #   fingerprint will be written
          def initialize(splitters:, orig:, target: :split_val,
            sort: :sort, indicator: :autosplit,
            fingerprint: :prepped_row_fingerprint)
            @splitters = splitters.is_a?(Hash) ? splitters.keys : splitters
            @orig = orig
            @target = target
            @sort = sort
            @indicator = indicator
            @fingerprint = Fingerprint::Add.new(
              fields: [:orig, target, sort],
              target: fingerprint
            )
            @splitinds = splitters.is_a?(Hash) ? splitters : nil
            @rows = []
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            val = row[orig]
            fail(BlankFcarOrigFieldError) if val.blank?

            row[:orig] = val
            row.delete(orig)
            matchers = splitters.select { |splitter| val.match?(splitter) }
            rows << prep_rows(row, val, matchers)

            nil
          end

          def close = rows.flatten
            .each { |row| yield fingerprint.process(row) }

          private

          attr_reader :splitters, :orig, :target, :sort, :indicator,
            :fingerprint, :splitinds, :rows

          def prep_rows(row, origval, matchers)
            return nonmatching_row(row, origval) if matchers.empty?

            matchers.inject(origval) { |res, nv| res.gsub(nv, UNIT_SEP) }
              .split(UNIT_SEP)
              .map
              .with_index { |v, i| prep_row(row, v, i, matchers, origval) }
          end

          def prep_row(row, v, i, matchers, origval)
            row.dup
              .merge({
                target => v.strip,
                sort => "#{origval} #{i.to_s.rjust(3, "0")}",
                indicator => get_inds(matchers)
              })
          end

          def get_inds(matchers) = if splitinds
                                     matchers.map { |m| splitinds[m] }
                                       .join(Kiba::Extend.delim)
                                   else
                                     "y"
                                   end

          def nonmatching_row(row, val)
            [row.merge({
              target => val,
              sort => "#{val} 000",
              indicator => splitinds ? nil : "n"
            })]
          end
        end
      end
    end
  end
end
