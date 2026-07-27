# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Kiba::Extend::Jobs::Job" do
  before(:all) do
    reg = Kiba::Extend::Registry::FileRegistry.new
    Kiba::Extend.config.registry = reg
    @dest_file = File.join(fixtures_dir, "base_job_dest.csv")
    entries = {
      dynamic_src: {
        dynamic_source: true,
        desc: "None"
      },
      base_src: {
        path: File.join(fixtures_dir, "base_job_base.csv"),
        supplied: true
      },
      missing_src: {
        path: File.join(fixtures_dir, "not_here.csv"),
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
    job.run
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

    it "runs and produces expected overridden lookup result" do
      job.run
      result = CSV.read(@dest_file)
      expect(result).to eq(expected_lookup_result)
    end
  end

  context "when using same lookup file with different lookup_ons" do
    let(:base_job_config) do
      {
        source: [:base_src],
        destination: ["base_dest"],
        lookup: [
          :base_lookup,
          {jobkey: :base_lookup, lookup_on: :number, name: :numlkup}
        ]
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
          fieldmap: {from_lkup: :word}
        transform Merge::MultiRowLookup,
          lookup: numlkup,
          keycolumn: :number,
          fieldmap: {punctuation: :punct}
      end
    end

    it "runs and produces expected multi-lookup result" do
      expected = [
        ["number", "alpha", "from_lkup", "punctuation"],
        ["one", "a", "aardvark", "comma"],
        ["two", "b", "bird", "bang"]
      ]

      job.run
      result = CSV.read(@dest_file)
      expect(result).to eq(expected)
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

    it "reports error to STDOUT" do
      expect { job.run }.to raise_error(SystemExit).and output(
        /.DEPENDENCY ERROR IN*/
      ).to_stdout_from_any_process
    end
  end

  context "when dynamic_source is given" do
    let(:base_job_config) do
      {
        source: [:dynamic_src],
        destination: [:base_dest],
        lookup: [:base_lookup]
      }
    end

    it "reports error to STDOUT" do
      expect { job.run }.to raise_error(SystemExit).and output(
        /REGISTEREDSOURCE FILE SETUP ERROR FOR: base_dest/
      ).to_stdout
    end
  end
end
