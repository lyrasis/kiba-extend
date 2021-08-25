# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::RegisteredFile' do
  let(:filekey){ :fkey }
  let(:path){ File.join('spec', 'fixtures', 'fkey.csv') }
  let(:default){ { path: path } }
  let(:dest){ Kiba::Extend::RegisteredFile.new(key: filekey, data: Kiba::Extend::FileRegistryEntry.new(data)) }

  context 'when called with no path' do
    let(:data){ {description: 'blah'} }
    it 'raises FileNotRegisteredError' do
      msg = "No file path for :#{filekey} is recorded in file registry hash"
      expect{ Kiba::Extend::RegisteredFile.new(key: filekey, data: Kiba::Extend::FileRegistryEntry.new(data)) }.to raise_error(Kiba::Extend::RegisteredFile::NoFilePathError, msg)
    end
  end

  describe '#key' do
    let(:result){ dest.key }
    context 'with basic defaults' do
      let(:data){ default }
      it 'returns file key' do
        expect(result).to eq(filekey)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
