# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::JobTest::Runner do
  subject(:runner) { described_class.new(config) }

  before(:all) { populate_registry }
  after(:all) { Kiba::Extend.reset_config }

  describe "call" do
    let(:result) { runner.call }

    context "with nonexistent test" do
      let(:config) do
        {
          job: :fkey,
          test: "CsvJob::Equals",
          path: "foo"
        }
      end

      it "returns as expected" do
        expect(result[:status]).to eq(:failure)
        expect(result[:got]).to eq("No Kiba::Extend::JobTest::CsvJob::Equals "\
                                   "job test class is defined")
      end
    end

    context "with bad test config" do
      let(:config) do
        {
          job: :fkey,
          test: "CsvJob::Equal",
          path: "foo",
          select_field: :objectnumber,
          select_value: "OBJ2",
          test_field: :numberofobjects
        }
      end

      it "returns as expected" do
        expect(result[:status]).to eq(:failure)
        expect(result[:got]).to match(/config requires key\(s\):/)
      end
    end

    context "with passing test" do
      let(:config) do
        {
          job: :fkey,
          test: "CsvJob::Equal",
          path: File.join(fixtures_dir, "existing.csv"),
          select_field: :objectnumber,
          select_value: "OBJ2",
          test_field: :numberofobjects,
          expected: "2"
        }
      end

      it "returns as expected" do
        expect(result[:status]).to eq(:success)
        expect(result[:got]).to be_nil
      end
    end

    context "with failing test" do
      let(:config) do
        {
          job: :fkey,
          test: "CsvJob::Equal",
          path: File.join(fixtures_dir, "existing.csv"),
          select_field: :objectnumber,
          select_value: "OBJ2",
          test_field: :numberofobjects,
          expected: "7"
        }
      end

      it "returns as expected" do
        expect(result[:status]).to eq(:failure)
        expect(result[:got]).to end_with(" 2")
      end
    end
  end
end
