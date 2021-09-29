# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::Sources::FileSet' do
  before(:context) do
    @path = File.join(fixtures_dir, 'fileset')
    FileUtils.mkdir(@path)
    FileUtils.touch(File.join(@path, 'a.csv'))
    FileUtils.touch(File.join(@path, 'b.csv'))
    FileUtils.touch(File.join(@path, 't.txt'))
    FileUtils.touch(File.join(@path, '.~lock.a.csv'))
  end
  after(:context) { FileUtils.rm_rf(@path) }

  let(:args) { { path: @path } }
  let(:set) { Kiba::Extend::Sources::FileSet.new(**args) }
  describe '#files' do
    let(:result) { set.files }
    context 'with defaults' do
      it 'returns expected files' do
        expect(result.length).to eq(4)
      end
    end

    context 'with include' do
      let(:args) { { path: @path, include: '.*\.csv$' } }
      it 'returns expected files' do
        expect(result.length).to eq(3)
      end
    end

    context 'with exclude' do
      let(:args) { { path: @path, exclude: '^\.~lock' } }
      it 'returns expected files' do
        expect(result.length).to eq(3)
      end
    end

    context 'with include and exclude' do
      let(:args) { { path: @path, include: '.*\.csv$', exclude: '^\.~lock' } }
      it 'returns expected files' do
        expect(result.length).to eq(2)
      end
    end

    context 'when recursive' do
      before(:context) do
        subdir = File.join(@path, 'subdir')
        FileUtils.mkdir(subdir)
        FileUtils.touch(File.join(subdir, 'd.csv'))
        FileUtils.touch(File.join(subdir, 'e.csv'))
        FileUtils.touch(File.join(subdir, 'f.xml'))
        FileUtils.touch(File.join(subdir, '.~lock.d.csv'))
      end
      context 'with include and exclude' do
        let(:args) { { path: @path, recursive: true, include: '.*\.csv$', exclude: '^\.~lock' } }
        it 'returns expected files' do
          expect(result.length).to eq(4)
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
