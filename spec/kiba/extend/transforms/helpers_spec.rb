# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Helpers do
  include Kiba::Extend::Transforms::Helpers
  
  describe '#delim_only?' do
    context 'when delim = |' do
      let(:delim) { '|' }
      let(:usenull) { false }
      let(:result) { delim_only?(value, delim, usenull) }
      context 'when value = foo|bar' do
        let(:value) { 'foo|bar' }
        it 'returns false' do
          expect(result).to be false
        end
      end
      context 'when value = |' do
        let(:value) { '|' }
        it 'returns true' do
          expect(result).to be true
        end
      end
      context 'when value = %NULLVALUE%|%NULLVALUE%' do
        let(:value) { '%NULLVALUE%|%NULLVALUE%' }
        it 'returns false' do
          expect(result).to be false
        end
      end
      context 'when value = %NULLVALUE%' do
        let(:value) { '%NULLVALUE%' }
        it 'returns false' do
          expect(result).to be false
        end
      end
      context 'when value = %NULLVALUE%|blah' do
        let(:value) { '%NULLVALUE%|blah' }
        it 'returns false' do
          expect(result).to be false
        end
      end
      context 'when value = blank' do
        let(:value) { '' }
        it 'returns false' do
          expect(result).to be false
        end
      end
      context 'when value = nil' do
        let(:value) { nil }
        it 'returns false' do
          expect(result).to be false
        end
      end
      context 'when value = " "' do
        let(:value) { ' ' }
        it 'returns false' do
          expect(result).to be false
        end
      end

      context 'when usenull = true' do
        let(:usenull) { true }
        context 'when value = %NULLVALUE%|%NULLVALUE%' do
          let(:value) { '%NULLVALUE%|%NULLVALUE%' }
          it 'returns true' do
            expect(result).to be true
          end
        end
        context 'when value = %NULLVALUE%' do
          let(:value) { '%NULLVALUE%' }
          it 'returns true' do
            expect(result).to be true
          end
        end
        context 'when value = %NULLVALUE%|blah' do
          let(:value) { '%NULLVALUE%|blah' }
          it 'returns false' do
            expect(result).to be false
          end
        end
      end
    end
  end

  describe '#field_values' do
    let(:row) { {
      a: nil,
      b: '',
      c: ';',
      d: 'foo',
      e: '%NULLVALUE%',
      f: '%NULLVALUE%;%NULLVALUE%'
    } }
    let(:fields) { %i[a b c d e f] }
    let(:discard) { %i[nil empty delim] }
    let(:delim) { ';' }
    let(:usenull) { false }
    let(:result) { field_values(row: row, fields: fields, discard: discard, delim: delim, usenull: usenull) }
    context 'with all fields and no discard values' do
      let(:discard) { %i[] }
      it 'returns all field values' do
        expect(result).to eq(row)
      end
    end

    context 'with all fields and default discard and usenull values' do
      it 'returns expected field values' do
        expected = {
          d: 'foo',
          e: '%NULLVALUE%',
          f: '%NULLVALUE%;%NULLVALUE%'
        }
        expect(result).to eq(expected)
      end
    end

    context 'with all fields, default discard, and usenull true' do
      let(:usenull) { true }
      it 'returns expected field values' do
        expected = {
          d: 'foo'
        }
        expect(result).to eq(expected)
      end
    end

    context 'with non-existent field, default discard, and usenull true' do
      let(:usenull) { true }
      let(:fields) { %i[d q] }
      it 'returns expected field values' do
        expected = {
          d: 'foo'
        }
        expect(result).to eq(expected)
      end
    end
  end
end
