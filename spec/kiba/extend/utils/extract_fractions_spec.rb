# frozen_string_literal: true

require 'spec_helper'

def fraction(params)
  Kiba::Extend::Data::ConvertibleFraction.new(**params)
end

RSpec.describe Kiba::Extend::Utils::ExtractFractions do
  subject(:xform){ described_class.new(**params) }
  
  describe '#call' do
    let(:result){ xform.call(val) }
    let(:results){ expectations.keys.map{ |val| xform.call(val) } }
    let(:expected){ expectations.values }

    context %{with defaults } do
      let(:params){ {} }
      let(:expectations) do
        {
          '1/4 x 9-1/4 x 1/4, 20, 3 3/4' => [
            fraction({whole: 3, fraction: '3/4', position: 23..27}),
            fraction({fraction: '1/4', position: 14..16}),
            fraction({whole: 9, fraction: '1/4', position: 6..10}),
            fraction({fraction: '1/4', position: 0..2})
          ],
          '6-1/4 x 9-1/4' => [
            fraction({whole: 9, fraction: '1/4', position: 8..12}),
            fraction({whole: 6, fraction: '1/4', position: 0..4})
          ],
          '123' => []
        }
      end

      it 'returns expected' do
        expect(results).to eq(expected)
      end
    end
  end
end
