# frozen_string_literal: true

require 'spec_helper'

class TestClass < Kiba::Extend::RegisteredFile
  include Kiba::Extend::RequirableFile
end

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::RequirableFile' do
  let(:filekey){ :fkey }
  let(:path){ File.join('spec', 'fixtures', 'fkey.csv') }
  let(:default){ { path: path, creator: lambda{Helpers.test_csv} } }
  let(:klass){ TestClass.new(key: filekey, data: data) }

  context 'when called without creator' do
    let(:data){ {path: path} }
    it 'raises NoDependencyCreatorError' do
      msg = "No creator method found for :#{filekey} in file registry hash"
      expect{ TestClass.new(key: filekey, data: data).required }.to raise_error(Kiba::Extend::RequirableFile::NoDependencyCreatorError, msg)
    end
  end
  
  describe '#required' do
    let(:result){ klass.required }
    context 'with basic defaults' do
      let(:data){ default }
      it 'returns lambda for creator' do
        expect(result).to be_a_kind_of(Proc)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
