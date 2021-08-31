# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::Registry::FileRegistry' do
  before(:context) do
    Kiba::Extend.config.registry = Kiba::Extend::Registry::FileRegistry.new
    populate_registry
  end
  let(:filekey) { :fkey }
  let(:fkeypath) { File.join(fixtures_dir, 'fkey.csv') }
  let(:registry) { Kiba::Extend.registry }
  let(:result) { registry.resolve(filekey) }

  describe 'initial setup and registration' do
    context 'when no namespace' do
      let(:data) { { path: fkeypath, supplied: true, lookup_on: :id } }
      it 'registers and resolves' do
        expect(result).to eq(data)
      end

      context 'with insufficient data' do
        let(:filekey) { :invalid }
        let(:data) { {} }
        it 'registers and resolves' do
          expect(result).to eq(data)
        end
      end
    end

    context 'with namespace' do
      it 'registers and resolves' do
        expect(registry.resolve('ns__sub__fkey')).to eq({ path: 'data', supplied: true })
      end
    end
  end

  # subsequent tests depend on the transformation having been done here
  describe 'post-transformation' do
    before(:context) { transform_registry }
    describe '#transform' do
      it 'converts all registered items to FileRegistryEntry objects' do
        chk = []
        registry.each { |item| chk << item[1].class }
        chk.uniq!
        expect(chk.length).to eq(1)
        expect(chk.first).to eq(Kiba::Extend::Registry::FileRegistryEntry)
      end
    end

    describe 'as destination' do
      let(:result) { registry.as_destination(filekey) }
      it 'returns destination file config' do
        expect(result).to be_a(Kiba::Extend::Registry::RegisteredDestination)
      end

      context 'when called with nonexistent key' do
        let(:filekey) { :cats }
        it 'raises error' do
          msg = "No file registered under the key: :#{filekey}"
          expect { result }.to raise_error(Kiba::Extend::Registry::FileRegistry::KeyNotRegisteredError, msg)
        end
      end
    end

    describe 'as lookup' do
      let(:result) { registry.as_lookup(filekey) }
      it 'returns lookup file config' do
        expect(result).to be_a(Kiba::Extend::Registry::RegisteredLookup)
      end
    end

    describe 'as source' do
      let(:result) { registry.as_source(filekey) }
      it 'returns source file config' do
        expect(result).to be_a(Kiba::Extend::Registry::RegisteredSource)
      end
    end

    describe 'entries' do
      let(:result) { registry.entries }
      it 'returns Array of FileRegistryEntries' do
        expect(result).to be_a(Array)
        expect(result.first).to be_a(Kiba::Extend::Registry::FileRegistryEntry)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
