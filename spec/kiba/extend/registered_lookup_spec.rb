# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::RegisteredLookup' do
  let(:filekey){ :fkey }
  let(:path){ File.join('spec', 'fixtures', 'fkey.csv') }
  let(:key){ :foo }
  let(:default){ { path: path, key: key, creator: lambda{Helpers.test_csv} } }
  let(:lookup){ Kiba::Extend::RegisteredLookup.new(key: filekey, data: data) }

  context 'when called without lookup key' do
    let(:data){ {path: path} }
    it 'raises NoLookupKeyError' do
      msg = "No lookup key found for :#{filekey} in file registry hash"
      expect{ lookup }.to raise_error(Kiba::Extend::RegisteredLookup::NoLookupKeyError, msg)
    end
  end
  
  describe '#args' do
    let(:result){ lookup.args }
    context 'with basic defaults' do
      let(:data){ default }
      let(:expected) do
        {file: path, csvopt: Kiba::Extend.csvopts, keycolumn: key}
      end
      it 'returns with default csvopts' do
        expect(result).to eq(expected)
      end
    end

    context 'with given options' do
      let(:override_opts){ {foo: :bar} }
      let(:data){ default.merge({src_opt: override_opts}) }
      let(:expected) do
        {file: path, csvopt: override_opts, keycolumn: key}
      end
      it 'returns with given options' do
        expect(result).to eq(expected)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
