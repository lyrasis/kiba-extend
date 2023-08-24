# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::Merge::ConstantValueConditional do
  subject(:merger) {
    described_class.new(fieldmap: fieldmap, condition: condition)
  }

  let(:fieldmap) { {reason: "gift", cost: "0"} }
  let(:condition) {
    ->(row) {
      row[:note].is_a?(String) && row[:note].match?(/gift|donation/i) && row[:type] != "obj"
    }
  }
  let(:input) do
    [
      {note: "Gift", type: "acq"},
      {reason: "donation", note: "Was a donation", type: "acq"},
      {note: "Was a donation", type: "obj"},
      {reason: "purchase", cost: "100", note: "Purchased from Someone",
       type: "acq"},
      {note: "", type: "acq"},
      {note: nil, type: "acq"}
    ]
  end

  describe "#process" do
    let(:result) { input.map { |row| merger.process(row) } }
    let(:expected) do
      [
        {reason: "gift", cost: "0", note: "Gift", type: "acq"},
        {reason: "gift", cost: "0", note: "Was a donation", type: "acq"},
        {reason: nil, cost: nil, note: "Was a donation", type: "obj"},
        {reason: "purchase", cost: "100", note: "Purchased from Someone",
         type: "acq"},
        {reason: nil, cost: nil, note: "", type: "acq"},
        {reason: nil, cost: nil, note: nil, type: "acq"}
      ]
    end

    it "transforms as expected" do
      expect(result).to eq(expected)
    end

    context "with condition lambda returning other than true/false" do
      let(:condition) { ->(row) { row[:note] } }

      it "raises error" do
        err = Kiba::Extend::Transforms::Merge::ConstantValueConditional::NonBooleanConditionError
        expect { result }.to raise_error(err)
      end
    end

    context "with condition lambda that throws an error" do
      let(:condition) {
        ->(row) {
          row[:note].match?(/gift|donation/i) && row[:type] != "obj"
        }
      }

      it "raises error" do
        msg = %(Condition lambda throws error with row: {:note=>nil, :type=>"acq"})
        err = Kiba::Extend::Transforms::Merge::ConstantValueConditional::ConditionError
        expect { result }.to raise_error(err, msg)
      end
    end
  end
end
