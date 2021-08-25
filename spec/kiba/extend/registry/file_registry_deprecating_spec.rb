# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::FileRegistryDeprecating' do
  let(:filekey){ [:fkey] }
  let(:fkeypath){ File.join('spec', 'fixtures', 'fkey.csv') }
  let(:reghash) do
    { 
      fkey: {path: fkeypath, key: :foo },
      foo: {path: fkeypath, creator: Helpers.method(:test_csv), tags: %i[test] },
      bar: {path: fkeypath, creator: Helpers.method(:lookup_csv), tags: %i[test report]},
      baz: {path: fkeypath, creator: Kiba::Extend::Utils::Lookup.method(:csv_to_hash), tags: %i[report]},
      namespace: {
        foo: {path: fkeypath, creator: Helpers.method(:test_csv), tags: %i[test] },
        sub: {
          fkey: {path: fkeypath},
          baz: {path: fkeypath, creator: Helpers.method(:test_csv), tags: %i[report]},
        }
      }
    }
  end
  let(:registry){ Kiba::Extend::FileRegistryDeprecating.new(reghash) }

  context 'with namespaced key' do
    let(:filekey){ [:namespace, :sub, :fkey] }
    let(:result){ registry.as_source(filekey) }
    
    it 'can lookup namespaced file hash' do
      expect(result).to be_a(Kiba::Extend::RegisteredSource)
    end

    it 'sends key built as expected' do
      expect(result.key).to eq(:"namespace/sub/fkey")
    end
  end

  describe 'as destination' do
    let(:result){ registry.as_destination(filekey) }
    it 'returns destination file config' do
      expect(result).to be_a(Kiba::Extend::RegisteredDestination)
    end
  end

  describe 'as source' do
    let(:result){ registry.as_source(filekey) }
    it 'returns source file config' do
      expect(result).to be_a(Kiba::Extend::RegisteredSource)
    end
    it 'sends key built as expected' do
      expect(result.key).to eq(:fkey)
    end
  end

  describe 'as lookup' do
    let(:result){ registry.as_lookup(filekey) }
    it 'returns lookup file config' do
      expect(result).to be_a(Kiba::Extend::RegisteredLookup)
    end
  end
end
# rubocop:enable Metrics/BlockLength
