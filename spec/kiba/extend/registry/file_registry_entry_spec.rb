# frozen_string_literal: true

require 'spec_helper'

# used to test creator validation below
module Helpers
  module Project
    module Section
      module_function
      def job
      end
    end
    module JoblessSection
      module_function
    end
  end
end

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::Registry::FileRegistryEntry' do
  let(:path) { File.join('spec', 'fixtures', 'fkey.csv') }
  let(:entry) { Kiba::Extend::Registry::FileRegistryEntry.new(data) }
  let(:reghash) do
    {
      fkey: { path: path, key: :foo },
      foo: { path: path, creator: Helpers.method(:test_csv), tags: %i[test] },
      bar: { path: path, creator: Helpers.method(:lookup_csv), tags: %i[test report] },
      baz: { path: path, creator: Kiba::Extend::Utils::Lookup.method(:csv_to_hash), tags: %i[report] },
      namespace: {
        foo: { path: path, creator: Helpers.method(:test_csv), tags: %i[test] },
        sub: {
          fkey: { path: path },
          baz: { path: path, creator: Helpers.method(:test_csv), tags: %i[report] },
        }
      }
    }
  end

  context 'with valid data' do
    let(:data) { { path: path, creator: Helpers.method(:test_csv) } }
    it 'valid as expected' do
      expect(entry.path).to eq(Pathname.new(path))
      expect(entry.valid?).to be true
    end
  end

  context 'without path' do
    context 'when CSV source/dest' do
      let(:data) { { pat: path, supplied: true } }
      it 'invalid as expected' do
        expect(entry.path).to be_nil
        expect(entry.valid?).to be false
        expect(entry.errors.key?(:missing_path)).to be true
      end
    end

    context 'when un-written source/dest' do
      let(:data) {
        { src_class: Kiba::Common::Sources::Enumerable,
         dest_class: Kiba::Common::Destinations::Lambda,
         supplied: true }
      }
      it 'valid as expected' do
        expect(entry.path).to be_nil
        expect(entry.valid?).to be true
      end
    end
  end

  context 'without creator' do
    context 'when supplied file' do
      let(:data) { { path: path, supplied: true } }
      it 'valid' do
        expect(entry.valid?).to be true
      end
    end

    context 'when not a supplied file' do
      let(:data) { { path: path } }
      it 'invalid as expected' do
        expect(entry.valid?).to be false
        expect(entry.errors[:missing_creator_for_non_supplied_file]).to be_nil
      end
    end
  end

  context 'with non-method creator' do
    context 'when a String' do
      let(:data) { { path: path, creator: 'a string' } }
      it 'invalid as expected' do
        expect(entry.creator).to be_nil
        expect(entry.valid?).to be false
        expect(entry.errors[:creator_not_a_method]).to eq('a string')
      end
    end

    context 'when a Module not containing a `job` method, and no method given' do
      let(:data) { { path: path, creator: Helpers::Project::JoblessSection } }
      it 'invalid as expected' do
        expect(entry.creator).to be_nil
        expect(entry.valid?).to be false
        expect(entry.errors[:creator_module_does_not_contain_default_job_method]).to eq('Helpers::Project::JoblessSection')
      end
    end

    context 'when a Module containing a `job` method, and no method given' do
      let(:data) { { path: path, creator: Helpers::Project::Section } }
      it 'valid as expected' do
        expect(entry.valid?).to be true
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
