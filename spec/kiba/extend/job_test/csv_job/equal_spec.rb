# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::JobTest::CsvJob::Equal do
  subject(:test) { described_class.new(config) }

  let(:test_csv) { File.join(fixtures_dir, "existing.csv") }

  context "when missing a required key" do
    let(:config) do
      {
        path: test_csv,
        select_field: :objectnumber,
        select_value: "OBJ2",
        test_field: :numberofobjects
      }
    end

    it "raises error" do
      expect { test }.to raise_error(/config requires key\(s\):/)
    end
  end

  describe "#result" do
    let(:result) { test.result }

    context "with passing test" do
      let(:config) do
        {
          path: test_csv,
          select_field: :objectnumber,
          select_value: "OBJ2",
          test_field: :numberofobjects,
          expected: "2"
        }
      end

      it "returns :success" do
        expect(result[:status]).to eq(:success)
      end
    end

    context "with failing test" do
      let(:config) do
        {
          path: test_csv,
          select_field: :objectnumber,
          select_value: "OBJ2",
          test_field: :numberofobjects,
          expected: "127"
        }
      end

      it "returns actual data value" do
        expect(result[:status]).to eq(:failure)
        expect(result[:got]).to end_with(" 2")
        expect(result[:desc]).to eq("When objectnumber is OBJ2, "\
                                    "numberofobjects == 127")
      end
    end

    context "when returns no rows" do
      let(:config) do
        {
          path: test_csv,
          select_field: :objectnumber,
          select_value: "OBJ27",
          test_field: :numberofobjects,
          expected: "19"
        }
      end

      it "returns no rows message" do
        expect(result[:status]).to eq(:failure)
        expect(result[:got]).to end_with("no rows matching select criteria")
      end
    end
  end
end
