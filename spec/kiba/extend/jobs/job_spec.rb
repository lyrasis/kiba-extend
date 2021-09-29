# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::Jobs::Job' do
  before(:context) do
    @dest_file = File.join(fixtures_dir, 'base_job_dest.csv')
    Kiba::Extend.config.registry = Kiba::Extend::Registry::FileRegistry.new
    entries = { base_src: { path: File.join(fixtures_dir, 'base_job_base.csv'), supplied: true },
                base_lookup: { path: File.join(fixtures_dir, 'base_job_lookup.csv'), supplied: true,
                               lookup_on: :letter },
                base_dest: { path: @dest_file, creator: Helpers.method(:fake_creator_method) }, }
    entries.each { |key, data| Kiba::Extend.registry.register(key, data) }
    transform_registry
  end
  before(:each) do
    FileUtils.rm(@dest_file) if File.exist?(@dest_file)
  end
  after(:each) do
    FileUtils.rm(@dest_file) if File.exist?(@dest_file)
  end

  let(:base_job) { Kiba::Extend::Jobs::Job.new(files: base_job_config, transformer: base_job_transforms) }
  let(:base_job_config) { { source: [:base_src], destination: ['base_dest'], lookup: [:base_lookup] } }
  let(:base_job_transforms) do
    Kiba.job_segment do
      transform Kiba::Extend::Transforms::Rename::Field, from: :letter, to: :alpha
      transform Merge::MultiRowLookup,
                lookup: base_lookup,
                keycolumn: :alpha,
                fieldmap: {
                  from_lkup: :word,
                },
                delim: Kiba::Extend.delim
    end
  end

  context 'with defaults' do
    let(:job) { base_job }
    context 'when dependency files exist' do
      it 'runs and produces expected result' do
        job
        result = CSV.read(@dest_file)
        expected = [['number', 'alpha', 'from_lkup'], ['1', 'a', 'aardvark'], ['2', 'b', 'bird']]
        expect(result).to eq(expected)
      end
    end

    context 'when dependency files do not exist' do
      let(:base_job_config) { { source: [:missing_src], destination: [:base_dest], lookup: [:base_lookup] } }
      
      it 'calls dependency creators',
        skip: 'cannot figure out how to test this in a timely manner. Will test manually for now.' do
        missing_file = File.join(fixtures_dir, 'base_job_missing.csv')
        creator = double()
        Kiba::Extend.config.registry = Kiba::Extend::Registry::FileRegistry.new
        entries = { base_lookup: { path: File.join(fixtures_dir, 'base_job_lookup.csv'), supplied: true, lookup_on: :letter },
                    base_dest: { path: @dest_file, creator: Helpers.method(:fake_creator_method) },
                    missing_src: { path: missing_file, creator: Helpers::BaseJob.method(:creator) } }
        entries.each { |key, data| Kiba::Extend.registry.register(key, data) }
        transform_registry
        testjob = Helpers::BaseJob.new(files: base_job_config)
        testjob.creator = creator
        expect(creator).to receive(:call)
        testjob.handle_requirements
      end
    end
    # raise_error(Kiba::Extend::Jobs::Runner::MissingDependencyError)
  end
end
# rubocop:enable Metrics/BlockLength
