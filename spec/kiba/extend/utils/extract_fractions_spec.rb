# frozen_string_literal: true

require "spec_helper"

def fraction(params)
  Kiba::Extend::Data::ConvertibleFraction.new(**params)
end

RSpec.describe Kiba::Extend::Utils::ExtractFractions do
  subject(:xform) { described_class.new(**params) }

  # describe '.initialize' do
  #   context 'with defaults' do
  #     let(:params){ {} }

  #     it 'has expected instance variables' do
  #       expect
  #     end
  #   end
  # end

  describe "#call" do
    let(:result) { xform.call(val) }
    let(:results) { expectations.keys.map { |val| xform.call(val) } }
    let(:expected) { expectations.values }

    context %(with defaults) do
      let(:params) { {} }
      let(:expectations) do
        {
          "2/3 x 9-7/8 x 1/4, 20, 3 3/4" => [
            fraction({whole: 3, fraction: "3/4", position: 23..27}),
            fraction({fraction: "1/4", position: 14..16}),
            fraction({whole: 9, fraction: "7/8", position: 6..10}),
            fraction({fraction: "2/3", position: 0..2})
          ],
          "6-1/2 x 9-1/4 and height unknown" => [
            fraction({whole: 9, fraction: "1/4", position: 8..12}),
            fraction({whole: 6, fraction: "1/2", position: 0..4})
          ],
          "123" => [],
          "measures 1/4ft" => [
            fraction({fraction: "1/4", position: 9..11})
          ],
          "7/16-1/4" => [
            fraction({fraction: "1/4", position: 5..7}),
            fraction({fraction: "7/16", position: 0..3})
          ]
        }
      end

      it "returns expected" do
        expect(results).to eq(expected)
      end
    end

    context %(with only ' ' as whole_fraction_sep) do
      let(:params) { {whole_fraction_sep: [" "]} }
      let(:expectations) do
        {
          "2/3 x 9-7/8 x 1/4, 20, 3 3/4" => [
            fraction({whole: 3, fraction: "3/4", position: 23..27}),
            fraction({fraction: "1/4", position: 14..16}),
            fraction({fraction: "7/8", position: 8..10}),
            fraction({fraction: "2/3", position: 0..2})
          ],
          "6-2/3 x 9-1/4 and height unknown" => [
            fraction({fraction: "1/4", position: 10..12}),
            fraction({fraction: "2/3", position: 2..4})
          ],
          "123" => [],
          "measures 1/4ft" => [
            fraction({fraction: "1/4", position: 9..11})
          ],
          "7/16-1/4" => [
            fraction({fraction: "1/4", position: 5..7}),
            fraction({fraction: "7/16", position: 0..3})
          ]
        }
      end

      it "returns expected" do
        expect(results).to eq(expected)
      end
    end

    context %(with un-convertable "fraction") do
      let(:params) { {} }
      let(:value) { "copy 1/0" }
      let(:result) { xform.call(value) }
      it "returns expected" do
        msg = "Kiba::Extend::Utils::ExtractFractions: "\
          "Unconvertible fraction: 1/0"
        expect(xform).to receive(:warn).with(msg)
        expect(result).to eq([fraction({fraction: "1/0", position: 5..7})])
      end
    end
  end
end
