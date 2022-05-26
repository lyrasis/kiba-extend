# frozen_string_literal: true

RSpec.describe Kiba::Extend::Transforms::Cspace::AddressCountry do
  let(:source){ :country }
  let(:transform){ Cspace::AddressCountry.new(source: source, keep_orig: false) }
  let(:result){ rows.map{ |row| transform.process(row) } }
  let(:rows) do
    [
      {country: 'Viet Nam'},
      {country: 'Shangri-La'},
      {country: ''},
      {country: nil},
      {foo: 'bar'},
      {country: 'US'}
    ]
  end

  context 'with different source/target fields' do
    context 'with keep_orig false' do
      let(:expected) do
        [
          {addresscountry: 'VN'},
          {addresscountry: nil},
          {addresscountry: ''},
          {addresscountry: nil},
          {foo: 'bar', addresscountry: nil},
          {addresscountry: 'US'}
        ]
      end
      
      it 'transforms as expected', :aggregate_failures do
        nomap = "KIBA WARNING: Cannot map addresscountry: No mapping for #{source} value: Shangri-La"
        expect(transform).to receive(:warn).with(nomap)
        nofield = "KIBA WARNING: Cannot map addresscountry: Field `#{source}` does not exist in source data"
        expect(transform).to receive(:warn).with(nofield)
        expect(result).to eq(expected)
      end
    end

    context 'with keep_orig true' do
      let(:transform){ Cspace::AddressCountry.new(source: source) }
      let(:expected) do
        [
          {country: 'Viet Nam', addresscountry: 'VN'},
          {country: 'Shangri-La', addresscountry: nil},
          {country: '', addresscountry: ''},
          {country: nil, addresscountry: nil},
          {foo: 'bar', addresscountry: nil},
          {country: 'US', addresscountry: 'US'}
        ]
      end
      
      it 'transforms as expected', :aggregate_failures do
        nomap = "KIBA WARNING: Cannot map addresscountry: No mapping for #{source} value: Shangri-La"
        expect(transform).to receive(:warn).with(nomap)
        nofield = "KIBA WARNING: Cannot map addresscountry: Field `#{source}` does not exist in source data"
        expect(transform).to receive(:warn).with(nofield)
        expect(result).to eq(expected)
      end
    end
  end
  
  context 'with in_place mapping (same source/target)' do
    context 'with keep_orig false' do
      let(:transform){ Cspace::AddressCountry.new(source: source, target: :country) }
      let(:expected) do
        [
          {country: 'VN'},
          {country: nil},
          {country: ''},
          {country: nil},
          {foo: 'bar', country: nil},
          {country: 'US'}
        ]
      end
      
      it 'transforms as expected', :aggregate_failures do
        nomap = "KIBA WARNING: Cannot map addresscountry: No mapping for #{source} value: Shangri-La"
        expect(transform).to receive(:warn).with(nomap)
        nofield = "KIBA WARNING: Cannot map addresscountry: Field `#{source}` does not exist in source data"
        expect(transform).to receive(:warn).with(nofield)
        expect(result).to eq(expected)
      end
    end

    context 'with keep_orig true' do
      let(:transform){ Cspace::AddressCountry.new(source: source, target: :country, keep_orig: true) }
      let(:expected) do
        [
          {country: 'VN'},
          {country: nil},
          {country: ''},
          {country: nil},
          {foo: 'bar', country: nil},
          {country: 'US'}
        ]
      end
      
      it 'transforms as expected', :aggregate_failures do
        nomap = "KIBA WARNING: Cannot map addresscountry: No mapping for #{source} value: Shangri-La"
        expect(transform).to receive(:warn).with(nomap)
        nofield = "KIBA WARNING: Cannot map addresscountry: Field `#{source}` does not exist in source data"
        expect(transform).to receive(:warn).with(nofield)
        expect(result).to eq(expected)
      end
    end
  end
end
