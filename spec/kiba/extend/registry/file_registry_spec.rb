# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::FileRegistry' do
  let(:filekey){ :fkey }
  let(:fkeypath){ File.join('spec', 'fixtures', 'fkey.csv') }
  let(:data){ {path: fkeypath} }
  let(:registry) { Kiba::Extend.registry }
  let(:result){ registry.resolve(filekey) }
  let(:reghash) do
    { 
      fee: {path: fkeypath, key: :foo },
      foo: {path: fkeypath, creator: Helpers.method(:test_csv), tags: %i[test] },
      bar: {path: fkeypath, creator: Helpers.method(:lookup_csv), tags: %i[test report]},
      baz: {path: fkeypath, creator: Kiba::Extend::Utils::Lookup.method(:csv_to_hash), tags: %i[report]},
    }
  end

  context 'when no namespace' do
    it 'registers and resolves' do
      reghash.each{ |key, data| registry.register(key, data) }
      registry.register(filekey, data)
      expect(result).to eq(data)
    end

    context 'with insufficient data' do
      let(:filekey){ :invalid }
      let(:data){ {} }
      it 'registers and resolves' do
        registry.register(filekey, data)
        expect(result).to eq(data)
      end
    end
  end

  context 'with namespace' do
    it 'registers and resolves' do
      registry.namespace(:ns) do
        namespace(:sub) do
          register(:fkey, {path: 'data'})
        end
      end
      expect(registry.resolve('ns.sub.fkey')).to eq({path: 'data'})
    end
  end

  describe '#transform' do
    it 'converts all registered items to FileRegistryEntry objects' do
      registry.transform
      chk = []
      registry.each{ |item| chk << item[1].class }
      chk.uniq!
      expect(chk.length).to eq(1)
      expect(chk.first).to eq(Kiba::Extend::FileRegistryEntry)
    end
  end

  describe '#created_by_class' do
    it 'returns entries created by given class or method' do
      res = registry.created_by_class('Kiba::Extend::Utils::Lookup')
      expect(res.length).to eq(1)
      expect(res.keys.sort).to eq(%w[baz])
      res = registry.created_by_class('Kiba::Extend')
      expect(res.length).to eq(1)
      expect(res.keys.sort).to eq(%w[baz])
      res = registry.created_by_class('Helpers')
      expect(res.length).to eq(2)
      expect(res.keys.sort).to eq(%w[bar foo])
    end
  end
  
  describe '#created_by_method' do
    it 'returns entries created by given method' do
      res = registry.created_by_method('Kiba::Extend::Utils::Lookup.csv_to_hash')
      expect(res.length).to eq(1)
      expect(res.keys.sort).to eq(%w[baz])
    end
  end

  describe '#invalid' do
    it 'reports invalid entries' do
      res = registry.invalid
      expect(res.length).to eq(1)
    end
  end

  describe '#tagged' do
    it 'returns entries tagged with given symbol' do
      res = registry.tagged(:test)
      expect(res.length).to eq(2)
      expect(res.keys.sort).to eq(%w[bar foo])
    end
  end

  # context 'with namespaced key' do
  #   let(:filekey){ [:namespace, :sub, :fkey] }
  #   let(:result){ registry.as_source(filekey) }
  
  #   xit 'can lookup namespaced file hash' do
  #     expect(result).to be_a(Kiba::Extend::RegisteredSource)
  #   end

  #   xit 'sends key built as expected' do
  #     expect(result.key).to eq(:"namespace/sub/fkey")
  #   end
  # end

  # describe 'as destination' do
  #   let(:result){ registry.as_destination(filekey) }
  #   xit 'returns destination file config' do
  #     expect(result).to be_a(Kiba::Extend::RegisteredDestination)
  #   end
  # end

  # describe 'as source' do
  #   let(:result){ registry.as_source(filekey) }
  #   xit 'returns source file config' do
  #     expect(result).to be_a(Kiba::Extend::RegisteredSource)
  #   end
  #   xit 'sends key built as expected' do
  #     expect(result.key).to eq(:fkey)
  #   end
  # end

  # describe 'as lookup' do
  #   let(:result){ registry.as_lookup(filekey) }
  #   xit 'returns lookup file config' do
  #     expect(result).to be_a(Kiba::Extend::RegisteredLookup)
  #   end
  # end

  # describe 'generated_files' do
  #   let(:result){ registry.generated_files }
  #   xit 'selects files with a creator method' do
  #     expect(result.length).to eq(5)
  #   end
  # end
end
# rubocop:enable Metrics/BlockLength
