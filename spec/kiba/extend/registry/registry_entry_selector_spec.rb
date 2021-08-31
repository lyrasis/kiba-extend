# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::Registry::RegistryEntrySelector' do
  before(:context) do
    Kiba::Extend.config.registry = Kiba::Extend::Registry::FileRegistry.new
    prepare_registry
  end
  let(:selector) { Kiba::Extend::Registry::RegistryEntrySelector.new }

  describe '#tagged_any' do
    let(:result) { selector.tagged_any(tags) }
    context 'with :test, :report' do
      let(:tags) { %w[test report] }
      it 'returns entries tagged with given symbol' do
        expect(result.length).to eq(3)
        expect(result.map(&:key).sort).to eq(%w[bar baz foo])
      end
    end
  end

  describe '#tagged_all' do
    let(:result) { selector.tagged_all(tags) }
    context 'with :test, :report' do
      let(:tags) { %w[test report] }
      it 'returns entries tagged with given symbols' do
        expect(result.length).to eq(1)
        expect(result.map(&:key).sort).to eq(%w[bar])
      end
    end
  end

  describe '#created_by_class' do
    let(:result) { selector.created_by_class(cstr) }
    context 'with Kiba::Extend::Utils::Lookup' do
      let(:cstr) { 'Kiba::Extend::Utils::Lookup' }
      it 'returns entries created by given class or method' do
        expect(result.length).to eq(1)
        expect(result.map(&:key).sort).to eq(%w[baz])
      end
    end

    context 'with Kiba::Extend' do
      let(:cstr) { 'Kiba::Extend' }
      it 'does not require full string match' do
        expect(result.length).to eq(1)
        expect(result.map(&:key).sort).to eq(%w[baz])
      end
    end

    context 'with Helpers' do
      let(:cstr) { 'Helpers' }
      it 'returns entries created by given class or method' do
        expect(result.length).to eq(2)
        expect(result.map(&:key).sort).to eq(%w[bar foo])
      end
    end
  end

  describe '#created_by_method' do
    let(:result) { selector.created_by_method(mstr) }
    context 'with Kiba::Extend::Utils::Lookup.csv_to_hash' do
      let(:mstr) { 'Kiba::Extend::Utils::Lookup.csv_to_hash' }
      it 'returns entries created by given method' do
        expect(result.length).to eq(1)
        expect(result.map(&:key).sort).to eq(%w[baz])
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
