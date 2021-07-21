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
end
