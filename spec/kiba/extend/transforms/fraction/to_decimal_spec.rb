# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Fraction::ToDecimal do
  subject(:xform){ described_class.new(**params) }

  describe 'process' do
    let(:result){ input.map{ |row| xform.process(row) } }
    
    let(:input) do
      [
        {dimensions: nil},
        {dimensions: ''},
        {dimensions: '6-1/4 x 9-1/4'},
        {dimensions: '10 5/8x13'},
        {dimensions: '1 2/3 x 5 1/2'},
        {dimensions: '2/3 x 1/2'}
      ]
    end

    context 'with defaults' do
      let(:params){ {fields: :dimensions} }
      let(:expected) do
        [
          {dimensions: nil},
          {dimensions: ''},
          {dimensions: '6.25 x 9.25'},
          {dimensions: '10.625x13'},
          {dimensions: '1.6667 x 5.5'},
          {dimensions: '0.6667 x 0.5'}
        ]
      end

      it 'transforms as expected' do
        expect(result).to eq(expected)
      end
    end
  end
end
