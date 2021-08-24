# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::FileRegistryEntry' do
  let(:path){ File.join('spec', 'fixtures', 'fkey.csv') }
  let(:entry){ Kiba::Extend::FileRegistryEntry.new(data) }
  let(:reghash) do
    { 
      fkey: {path: path, key: :foo },
      foo: {path: path, creator: Helpers.method(:test_csv), tags: %i[test] },
      bar: {path: path, creator: Helpers.method(:lookup_csv), tags: %i[test report]},
      baz: {path: path, creator: Kiba::Extend::Utils::Lookup.method(:csv_to_hash), tags: %i[report]},
      namespace: {
        foo: {path: path, creator: Helpers.method(:test_csv), tags: %i[test] },
        sub: {
          fkey: {path: path},
          baz: {path: path, creator: Helpers.method(:test_csv), tags: %i[report]},
        }
      }
    }
  end

  context 'with valid data' do
    let(:data){ {path: path, creator: Helpers.method(:test_csv)} }
    it 'valid as expected' do
      expect(entry.path).to eq(path)
      expect(entry.valid?).to be true
    end
  end

  context 'without path' do
    let(:data){ {pat: path} }
    it 'invalid as expected' do
      expect(entry.path).to be_nil
      expect(entry.valid?).to be false
      expect(entry.errors.key?(:missing_path)).to be true
    end
  end

  context 'with non-method creator' do
    let(:data){ {path: path, creator: 'a string'} }
    it 'invalid as expected' do
      expect(entry.creator).to be_nil
      expect(entry.valid?).to be false
      expect(entry.errors[:creator_not_a_method]).to eq('a string')
    end
  end
end
# rubocop:enable Metrics/BlockLength
