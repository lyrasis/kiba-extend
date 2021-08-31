# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::Registry::RegisteredSource' do
  let(:filekey) { :fkey }
  let(:path) { File.join('spec', 'fixtures', 'fkey.csv') }
  let(:default) { { path: path, creator: -> { Helpers.test_csv } } }
  let(:source) do
    Kiba::Extend::Registry::RegisteredSource.new(
      key: filekey,
      data: Kiba::Extend::Registry::FileRegistryEntry.new(data)
    )
  end

  describe '#args' do
    let(:result) { source.args }
    context 'with basic defaults' do
      let(:data) { default }
      let(:expected) do
        [{ filename: path, csv_options: Kiba::Extend.csvopts }]
      end
      it 'returns with Kiba::Extend default csvopts' do
        expect(result).to eq(expected)
      end
    end

    context 'with given options' do
      let(:override_opts) { { foo: :bar } }
      let(:data) { { path: path, src_opt: override_opts } }
      let(:expected) do
        [{ filename: path, csv_options: override_opts }]
      end
      it 'returns with given opts' do
        expect(result).to eq(expected)
      end
    end
  end

  describe '#klass' do
    let(:result) { source.klass }
    context 'with basic defaults' do
      let(:data) { default }
      it 'returns Kiba::Extend default source class' do
        expect(result).to eq(Kiba::Extend.source)
      end
    end

    context 'with a given class' do
      let(:override_klass) { Kiba::Common::Destinations::CSV }
      let(:data) { { path: path, src_class: override_klass } }
      it 'returns given class' do
        expect(result).to eq(override_klass)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
