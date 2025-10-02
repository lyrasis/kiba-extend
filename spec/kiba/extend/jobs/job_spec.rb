# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe "Kiba::Extend::Jobs::Job" do
  before(:all) do
    reg = Kiba::Extend::Registry::FileRegistry.new
    Kiba::Extend.config.registry = reg
    @dest_file = File.join(fixtures_dir, "base_job_dest.csv")
    entries = {
      base_src: {
        path: File.join(fixtures_dir, "base_job_base.csv"),
        supplied: true
      },
      base_lookup: {
        path: File.join(fixtures_dir, "base_job_lookup.csv"),
        supplied: true,
        lookup_on: :letter
      },
      base_dest: {
        path: @dest_file,
        creator: Helpers.method(:fake_creator_method)
      }
    }
    entries.each { |key, data| Kiba::Extend.registry.register(key, data) }
    transform_registry
  end
  after(:all) { Kiba::Extend.reset_config }
  before(:each) do
    FileUtils.rm(@dest_file) if File.exist?(@dest_file)
  end
  after(:each) do
    FileUtils.rm(@dest_file) if File.exist?(@dest_file)
  end

  let(:base_job) do
    Kiba::Extend::Jobs::Job.new(
      files: base_job_config,
      transformer: base_job_transforms
    )
  end
  let(:base_job_config) do
    {
      source: [:base_src],
      destination: ["base_dest"],
      lookup: [:base_lookup]
    }
  end
  let(:base_job_transforms) do
    Kiba.job_segment do
      transform Kiba::Extend::Transforms::Rename::Field,
        from: :letter,
        to: :alpha
      transform Merge::MultiRowLookup,
        lookup: base_lookup,
        keycolumn: :alpha,
        fieldmap: {
          from_lkup: :word
        },
        delim: Kiba::Extend.delim
    end
  end

  let(:expected_lookup_result) do
    [
      ["number", "alpha", "from_lkup"],
      ["one", "a", "aardvark"],
      ["two", "b", "bird"]
    ]
  end

  let(:job) { base_job }

  it "runs and produces expected result" do
    job
    result = CSV.read(@dest_file)
    expect(result).to eq(expected_lookup_result)
  end

  context "when overriding lookup_on for a lookup" do
    let(:base_job_config) do
      {
        source: [:base_src],
        destination: ["base_dest"],
        lookup: {jobkey: :base_lookup, lookup_on: :number}
      }
    end

    let(:base_job_transforms) do
      Kiba.job_segment do
        transform Kiba::Extend::Transforms::Rename::Field,
          from: :letter,
          to: :alpha
        transform Merge::MultiRowLookup,
          lookup: base_lookup,
          keycolumn: :number,
          fieldmap: {
            from_lkup: :word
          },
          delim: Kiba::Extend.delim
      end
    end

    it "runs and produces expected result" do
      job
      result = CSV.read(@dest_file)
      expect(result).to eq(expected_lookup_result)
    end
  end

  context "when dependency files do not exist" do
    let(:base_job_config) do
      {
        source: [:missing_src],
        destination: [:base_dest],
        lookup: [:base_lookup]
      }
    end

    it "calls dependency creators",
      skip: "cannot figure out how to test this in a timely manner. Will "\
      "test manually for now." do
        missing_file = File.join(fixtures_dir, "base_job_missing.csv")
        creator = double
        Kiba::Extend.config.registry =
          Kiba::Extend::Registry::FileRegistry.new
        entries = {base_lookup: {
                     path: File.join(fixtures_dir, "base_job_lookup.csv"),
                     supplied: true, lookup_on: :letter
                   },
                   base_dest: {path: @dest_file,
                               creator: Helpers.method(:fake_creator_method)},
                   missing_src: {path: missing_file,
                                 creator: Helpers::BaseJob.method(:creator)}}
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
# rubocop:enable Metrics/BlockLength
