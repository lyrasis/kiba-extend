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
    let(:expected) do
      {
        klass: Kiba::Extend::Destinations::CSV,
        args: {filename: fkeypath, csv_options: Kiba::Extend.csvopts},
        info: {filekey: :fkey, desc: 'description'}
      }
    end
    
    it 'returns destination file config' do
      expect(result).to eq(expected)
    end
  end

  describe 'as source' do
    context 'when file does not exist' do
      let(:filekey){ :fkey }
      let(:result){ registry.as_source(filekey) }
      let(:expected) do
        {
          klass: Kiba::Common::Sources::CSV,
          args: {filename: fkeypath, csv_options: Kiba::Extend.csvopts},
          info: {filekey: :fkey, desc: 'description'},
          require: { module: Kiba::Extend, method: :config }
        }
      end
      
      it 'returns source file config with require key' do
        expect(result).to eq(expected)
      end
    end

    context 'when file exists' do
      let(:fkeypath){ File.join('spec', 'fixtures', 'existing.csv') }
      let(:filekey){ :fkey }
      let(:result){ registry.as_source(filekey) }
      let(:expected) do
        {
          klass: Kiba::Common::Sources::CSV,
          args: {filename: fkeypath, csv_options: Kiba::Extend.csvopts},
          info: {filekey: :fkey, desc: 'description'}
        }
      end
      
      it 'returns source file config without require key' do
        expect(result).to eq(expected)
      end
    end
  end

  describe 'as lookup' do
    context 'when file does not exist' do
      let(:filekey){ :fkey }
      let(:result){ registry.as_lookup(filekey) }
      let(:expected) do
        {
          args: {file: fkeypath, csvopt: Kiba::Extend.csvopts, keycolumn: :objectnumber},
          info: {filekey: :fkey, desc: 'description'},
          require: { module: Kiba::Extend, method: :config }
        }
      end
      
      it 'returns destination file config' do
        expect(result).to eq(expected)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
