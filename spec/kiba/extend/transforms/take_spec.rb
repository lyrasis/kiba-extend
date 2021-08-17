# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Take do
  let(:test_csv){ 'tmp/test.csv' }
  let(:result){ execute_job(filename: test_csv, xform: transform, xformopt: opts) }
  before do
    generate_csv(test_csv, rows)
  end
  after do
    File.delete(test_csv) if File.exist?(test_csv)
  end

  describe 'First' do
    let(:transform) { Take::First }
    let(:rows){ [
      %w[a b],
      ['c|d', 'e|j'],
      ['', nil],
      ['|f', 'g|'],
      ['h', 'i']
    ] }

    context 'when a, b -> y, z' do
      let(:opts){ { fields: %i[a b], targets: %i[y z], delim: '|' } }
      it 'outputs as expected' do
        expected = [
          { a: 'c|d', b: 'e|j', y: 'c', z: 'e' },
          { a: '', b: nil, y: '', z: nil },
          { a: '|f', b: 'g|', y: '', z: 'g' },
          { a: 'h', b: 'i', y: 'h', z: 'i' }
        ]
        expect(result).to eq(expected)
      end
    end

    context 'when a, b -> y' do
      let(:opts){ { fields: %i[a b], targets: %i[y], delim: '|' } }
      it 'outputs as expected' do
        expected = [
          { a: 'c|d', b: 'e', y: 'c'},
          { a: '', b: nil, y: ''},
          { a: '|f', b: 'g', y: ''},
          { a: 'h', b: 'i', y: 'h'}
        ]
        expect(result).to eq(expected)
      end
    end

    context 'when a, b -> nil, y' do
      let(:opts){ { fields: %i[a b], targets: [nil, :y], delim: '|' } }
      it 'outputs as expected' do
        expected = [
          { a: 'c', b: 'e|j', y: 'e'},
          { a: '', b: nil, y: nil},
          { a: '', b: 'g|', y: 'g'},
          { a: 'h', b: 'i', y: 'i'}
        ]
        expect(result).to eq(expected)
      end
    end

    context 'when a, b -> blankstring, z' do
      let(:opts){ { fields: %i[a b], targets: ['', :y], delim: '|' } }
      it 'outputs as expected' do
        expected = [
          { a: 'c', b: 'e|j', y: 'e'},
          { a: '', b: nil, y: nil},
          { a: '', b: 'g|', y: 'g'},
          { a: 'h', b: 'i', y: 'i'}
        ]
        expect(result).to eq(expected)
      end
    end

    context 'when a, b -> no targets' do
      let(:opts){ { fields: %i[a b], delim: '|' } }
      it 'outputs as expected' do
        expected = [
          { a: 'c', b: 'e' },
          { a: '', b: nil },
          { a: '', b: 'g' },
          { a: 'h', b: 'i' }
        ]
        expect(result).to eq(expected)
      end
    end
  end
end
