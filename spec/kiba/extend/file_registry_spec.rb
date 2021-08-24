# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::FileRegistry' do
  let(:fkeypath){ File.join('spec', 'fixtures', 'fkey.csv') }
  let(:reghash) do
    { 
      fkey: { path: fkeypath,
             dest_class: Kiba::Extend.destination, dest_opt: Kiba::Extend.csvopts,
             src_class: Kiba::Extend.source, src_opt: Kiba::Extend.csvopts,
             creator_module: Kiba::Extend, creator_method: :config,
             key: :objectnumber, desc: 'description' }
    }
  end
  let(:registry){ Kiba::Extend::FileRegistry.new(reghash) }

  describe 'as destination' do
    let(:filekey){ :fkey }
    let(:result){ registry.as_destination(filekey) }

    it 'returns destination file config' do
      expect(result).to be_a(Kiba::Extend::RegisteredDestination)
    end
  end

  describe 'as source' do
    context 'when file does not exist' do
      let(:filekey){ :fkey }
      let(:result){ registry.as_source(filekey) }
      it 'returns source file config' do
        expect(result).to be_a(Kiba::Extend::RegisteredSource)
      end
    end
  end

  describe 'as lookup' do
    context 'when file does not exist' do
      let(:filekey){ :fkey }
      let(:result){ registry.as_lookup(filekey) }
      it 'returns lookup file config' do
        expect(result).to be_a(Kiba::Extend::RegisteredLookup)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
