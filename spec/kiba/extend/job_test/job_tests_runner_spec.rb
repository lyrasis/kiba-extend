# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::JobTest::JobTestsRunner do
  subject(:runner) { described_class.new(job, tests) }

  before(:all) { populate_registry }
  after(:all) { Kiba::Extend.reset_config }

  describe "call" do
    let(:result) { runner.call }

    context "with nonexistent job" do
      let(:job) { :fkeys }
      let(:tests) do
        [
          {
            job: :fkeys,
            test: "CsvJob::Equal"
          }
        ]
      end

      it "returns as expected" do
        expect(result.first[:status]).to eq(:failure)
        expect(result.first[:got]).to eq("fkeys job does not exist in registry")
      end
    end

    context "with job without output" do
      let(:job) { :noresultfile }
      let(:tests) do
        [
          {
            job: :noresultfile,
            test: "CsvJob::Equal"
          }
        ]
      end

      it "returns as expected" do
        expect(result.first[:status]).to eq(:failure)
        expect(result.first[:got]).to eq("There is no output for the "\
                                         "noresultfile job")
      end
    end
  end
end
