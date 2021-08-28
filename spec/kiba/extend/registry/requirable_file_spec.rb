# frozen_string_literal: true

require 'spec_helper'

class TestClass < Kiba::Extend::RegisteredFile
  include Kiba::Extend::RequirableFile
end

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::RequirableFile' do
  let(:filekey){ :fkey }
  let(:path){ File.join('spec', 'fixtures', 'fkey.csv') }
  let(:default){ { path: path, creator: Helpers.method(:fake_creator_method) } }
  let(:klass){ TestClass.new(key: filekey, data: Kiba::Extend::FileRegistryEntry.new(data)) }

  context 'when called without creator' do
    let(:data){ {path: path} }
    it 'raises NoDependencyCreatorError' do
      msg = "No creator method found for :#{filekey} in file registry"
      expect{ TestClass.new(key: filekey, data: Kiba::Extend::FileRegistryEntry.new(data)).required }.to raise_error(Kiba::Extend::RequirableFile::NoDependencyCreatorError, msg)
    end
  end
  
  describe '#required' do
    let(:result){ klass.required }
    let(:data){ default }
    context 'when file does not exist at path' do
      it 'returns creator Method' do
        expect(result).to eq(Helpers.method(:fake_creator_method))
      end
    end

    context 'when file exists at path' do
      let(:path){ File.join(fixtures_dir, 'base_job_base.csv') }
      it 'returns nil' do
        expect(result).to be nil
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
