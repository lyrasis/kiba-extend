# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Replace
        # Provides the most-frequently used literal form for normalized
        #   values.
        #
        # The examples here will discuss names, but this transform can be
        #   applied to any kind of values.
        #
        # **REQUIRES:**
        #
        # - one field having original name values (including all minor variants
        #   that are removed by normalization
        # - one field having the normalized name values
        #
        # The transform does not care what normalization algorithm was applied
        #   to derive the normalized values
        #
        # **Notes on examples below:**
        #
        # - In the "With defaults" example, the normalized form is replaced by
        #   the most frequently used form
        # - In the "With target" example, the most frequently used form is put
        #   in the specified target field, leaving original normalized value
        #   in place
        # - When there's a tie among most frequently-used forms, the
        #   first-encountered form is used
        #
        # @example With defaults
        #   # Used in pipeline as:
        #   # transform Replace::NormWithMostFrequentlyUsedForm,
        #   #   normfield: :norm,
        #   #   nonnormfield: :name
        #   xform = Replace::NormWithMostFrequentlyUsedForm.new(
        #     normfield: :norm,
        #     nonnormfield: :name
        #   )
        #   input = [
        #     {name: "Smith, R. J.", norm: "smithrj"},
        #     {name: "Smith, R. J.", norm: "smithrj"},
        #     {name: "Smith, R.J.", norm: "smithrj"},
        #     {name: "Smith, RJ", norm: "smithrj"},
        #     {name: "Fields, J.T.", norm: "fieldsjt"},
        #     {name: "Fields, J. T.", norm: "fieldsjt"},
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {name: "Smith, R. J.", norm: "Smith, R. J."},
        #     {name: "Smith, R. J.", norm: "Smith, R. J."},
        #     {name: "Smith, R.J.", norm: "Smith, R. J."},
        #     {name: "Smith, RJ", norm: "Smith, R. J."},
        #     {name: "Fields, J.T.", norm: "Fields, J.T."},
        #     {name: "Fields, J. T.", norm: "Fields, J.T."},
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example With target
        #   # Used in pipeline as:
        #   # transform Replace::NormWithMostFrequentlyUsedForm,
        #   #   normfield: :norm,
        #   #   nonnormfield: :name,
        #   #   target: :pref
        #   xform = Replace::NormWithMostFrequentlyUsedForm.new(
        #     normfield: :norm,
        #     nonnormfield: :name,
        #     target: :pref
        #   )
        #   input = [
        #     {name: "Smith, R. J.", norm: "smithrj"},
        #     {name: "Smith, R. J.", norm: "smithrj"},
        #     {name: "Smith, R.J.", norm: "smithrj"},
        #     {name: "Smith, RJ", norm: "smithrj"},
        #     {name: "Fields, J.T.", norm: "fieldsjt"},
        #     {name: "Fields, J. T.", norm: "fieldsjt"},
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {name: "Smith, R. J.", norm: "smithrj", pref: "Smith, R. J."},
        #     {name: "Smith, R. J.", norm: "smithrj", pref: "Smith, R. J."},
        #     {name: "Smith, R.J.", norm: "smithrj", pref: "Smith, R. J."},
        #     {name: "Smith, RJ", norm: "smithrj", pref: "Smith, R. J."},
        #     {name: "Fields, J.T.", norm: "fieldsjt", pref: "Fields, J.T."},
        #     {name: "Fields, J. T.", norm: "fieldsjt", pref: "Fields, J.T."},
        #   ]
        #   expect(result).to eq(expected)
        class NormWithMostFrequentlyUsedForm
          # @param normfield [Symbol] field in which normalized form is
          #   initially found. Will be replaced with most frequently used form,
          #   unless :target is given
          # @param nonnormfield [Symbol] field in which non-normalized form of
          #   name is found
          # @param target [nil, Symbol] field in which most frequently used
          #   form of normalized value will be entered
          def initialize(normfield:, nonnormfield:, target: nil)
            @normfield = normfield
            @nonnormfield = nonnormfield
            @target = target ||= normfield
            @data = {}
            @rows = []
            @lookup = {}
          end

          def process(row)
            populate_data(row)
            rows << row
            nil
          end

          def close
            populate_lookup
            rows.each do |row|
              finalize(row)
              yield row
            end
          end

          private

          attr_reader :normfield, :nonnormfield, :target, :data, :rows, :lookup

          def populate_data(row)
            norm = row[normfield]
            orig = row[nonnormfield]

            if data.key?(norm)
              if data[norm].key?(orig)
                data[norm][orig] += 1
              else
                data[norm][orig] = 1
              end
            else
              data[norm] = {orig => 1}
            end
          end

          def populate_lookup
            data.each do |norm, cts|
              lookup[norm] = most_frequent(cts)
            end
          end

          def most_frequent(cts)
            cts.max_by { |a| a[1] }
              .first
          end

          def finalize(row)
            norm = row[normfield]
            row[target] = lookup[norm]
          end
        end
      end
    end
  end
end
