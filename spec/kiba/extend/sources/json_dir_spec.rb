# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::Sources::JsonDir' do
  subject(:src){ Kiba::Extend::Sources::JsonDir }
  let(:path){ File.join(fixtures_dir, 'json_dir') }

  describe '#each' do
    context 'with filename as only param' do
      it 'yields `Hash`es' do
        result = []
        source = src.new(dirpath: path)
        source.each{ |rec| result << rec }
        expect(result.length).to eq(2)
        expect(result.first).to be_a(Hash)
        expect(result.first.key?(:title)).to be true
      end
    end

    context 'when recursive' do
      it 'yields `Hash`es' do
        result = []
        source = src.new(dirpath: path, recursive: true)
        source.each{ |rec| result << rec }
        expect(result.length).to eq(3)
        expect(result.first).to be_a(Hash)
      end
    end

    context 'when recursive and filesuffixes includes .txt' do
      it 'yields `Hash`es' do
        result = []
        source = src.new(
          dirpath: path,
          recursive: true,
          filesuffixes: ['.json', '.txt']
        )
        source.each{ |rec| result << rec }
        expect(result.length).to eq(4)
        expect(result.first).to be_a(Hash)
      end
    end

    context 'when a file cannot be read/parsed' do
      it 'warns but does not yield' do
        result = []
        source = src.new(dirpath: path, filesuffixes: ['.json', '.err'])
        errpath = "#{path}/5.err"
        msg = "Cannot read/parse #{errpath}"
        expect(source).to receive(:warn).with(msg)
        source.each{ |rec| result << rec }
        expect(result.length).to eq(2)
      end
    end
  end
end

# rubocop:enable Metrics/BlockLength
