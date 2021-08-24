# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::FileRegistry' do
  let(:filekey){ [:fkey] }
  let(:fkeypath){ File.join('spec', 'fixtures', 'fkey.csv') }
  let(:reghash) do
    { 
      fkey: {path: fkeypath, key: :foo },
      namespace: {
        subnamespace: {
          fkey: {path: fkeypath}
        }
      }
    }
  end
  let(:registry){ Kiba::Extend::FileRegistry.new(reghash) }

  context 'with namespaced key' do
    let(:filekey){ [:namespace, :subnamespace, :fkey] }
    let(:result){ registry.as_source(filekey) }
    
    it 'can lookup namespaced file hash' do
      expect(result).to be_a(Kiba::Extend::RegisteredSource)
    end

    it 'sends key built as expected' do
      expect(result.key).to eq(:"namespace/subnamespace/fkey")
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
