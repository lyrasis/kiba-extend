# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe "Kiba::Extend::Jobs::TestingJob" do
  let(:test_job) do
    Kiba::Extend::Jobs::TestingJob.new(files: test_job_config,
      transformer: test_job_transforms)
  end
  let(:test_job_config) do
    {source: src, destination: dest, lookup: [[lkup1, :foo], [lkup2, :baz]]}
  end
  let(:src) { [{foo: 1, bar: 2}, {foo: 3, bar: 4}] }
  let(:dest) { [] }
  let(:lkup1) { [{foo: 1, baz: "a"}, {foo: 3, baz: "c"}] }
  let(:lkup2) { [{baz: "a", bat: "alpaca"}, {baz: "c", bat: "cat"}] }
  let(:test_job_transforms) do
    Kiba.job_segment do
      transform Kiba::Extend::Transforms::Rename::Field, from: :bar, to: :baz
      transform Merge::MultiRowLookup,
        lookup: lkup1,
        keycolumn: :foo,
        fieldmap: {
          letter: :baz
        },
        delim: Kiba::Extend.delim
      transform Merge::MultiRowLookup,
        lookup: lkup2,
        keycolumn: :letter,
        fieldmap: {
          animal: :bat
        },
        delim: Kiba::Extend.delim
    end
  end

  context "with defaults" do
    let(:job) { test_job }
    context "when dependency files exist" do
      it "runs and produces expected result",
        skip: "testing job does not yet support lookups" do
        job
        expected = [{foo: 1, baz: 2, letter: "a", animal: "alpaca"},
          {foo: 3, baz: 4, letter: "c", animal: "cat"}]
        expect(dest).to eq(expected)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
