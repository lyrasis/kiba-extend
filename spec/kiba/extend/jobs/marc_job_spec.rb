# frozen_string_literal: true

require 'marc'
require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::Jobs::MarcJob' do
  subject(:marcjob) do
    Kiba::Extend::Jobs::MarcJob.new(files: config, transformer: xforms)
  end

  context 'with Marc source, CSV dest' do
    before(:context) do
      reg = Kiba::Extend::Registry::FileRegistry.new
      Kiba::Extend.config.registry = reg
      @dest_file = File.join(fixtures_dir, 'marc_job_dest.csv')
      FileUtils.rm(@dest_file) if File.exist?(@dest_file)
      entries = {
        marc_src: {
          path: marc_file,
          supplied: true,
          src_class: Kiba::Extend::Sources::Marc
        },
        marc_dest: {
          path: @dest_file,
          creator: Helpers.method(:fake_creator_method)
        }
      }
      entries.each { |key, data| Kiba::Extend.registry.register(key, data) }
      transform_registry
    end
    after(:context) do
      Kiba::Extend.reset_config
      FileUtils.rm(@dest_file) if File.exist?(@dest_file)
    end

    let(:config) do
      {
        source: [:marc_src],
        destination: [:marc_dest]
      }
    end

    let(:xforms) do
      Kiba.job_segment do
        transform Kiba::Extend::Transforms::Marc::Extract245Title
      end
    end

    it 'runs and produces expected result' do
      marcjob
      result = CSV.table(@dest_file)
      expect(result).to be_a(CSV::Table)
    end
  end

  context 'with Marc source, Marc dest' do
    before(:context) do
      reg = Kiba::Extend::Registry::FileRegistry.new
      Kiba::Extend.config.registry = reg
      @dest_file = File.join(fixtures_dir, 'marc_job_dest.mrc')
      FileUtils.rm(@dest_file) if File.exist?(@dest_file)
      entries = {
        marc_src: {
          path: marc_file,
          supplied: true,
          src_class: Kiba::Extend::Sources::Marc
        },
        marc_dest: {
          path: @dest_file,
          creator: Helpers.method(:fake_creator_method),
          dest_class: Kiba::Extend::Destinations::Marc
        }
      }
      entries.each { |key, data| Kiba::Extend.registry.register(key, data) }
      transform_registry
    end
    after(:context) do
      Kiba::Extend.reset_config
      FileUtils.rm(@dest_file) if File.exist?(@dest_file)
    end

    let(:config) do
      {
        source: [:marc_src],
        destination: [:marc_dest]
      }
    end

    let(:xforms) do
      Kiba.job_segment do
      end
    end

    let(:recs) do
      recs = []
      MARC::Reader.new(@dest_file).each{ |rec| recs << rec }
      recs
    end

    it 'runs and produces expected result' do
      marcjob
      expect(recs.first).to be_a(MARC::Record)
      expect(recs.length).to eq(10)
    end
  end
end
# rubocop:enable Metrics/BlockLength
