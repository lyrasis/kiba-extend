# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Helpers do
  include Kiba::Extend::Transforms::Helpers

  describe '#empty?' do
    let(:result){ empty?(val) }

    context 'with non-empty string' do
      let(:val){ 'something' }

      it 'returns false' do
        expect(result).to be false
      end
    end

    context 'with nil' do
      let(:val){ nil }

      it 'returns true' do
        expect(result).to be true
      end
    end

    context 'with empty string' do
      let(:val){ '' }

      it 'returns true' do
        expect(result).to be true
      end
    end

    context 'with space-only string' do
      let(:val){ '   ' }

      it 'returns true' do
        expect(result).to be true
      end
    end
    
    context 'with space-and-tab string' do
      let(:val){ " \t " }

      it 'returns true' do
        expect(result).to be true
      end
    end

    context 'with config.nullvalue string' do
      let(:val){ Kiba::Extend.nullvalue }
      
      context 'with usenull false (default)' do
        it 'returns false' do
          expect(result).to be false
        end
      end

      context 'with usenull true' do
        let(:result){ empty?(val, true) }
        
        it 'returns true' do
          expect(result).to be true
        end
      end
    end
  end
end
