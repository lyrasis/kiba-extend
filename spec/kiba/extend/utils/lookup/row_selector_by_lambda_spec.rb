# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Utils::Lookup::RowSelectorByLambda do
  let(:origrow) { {source: "adopted"} }
  let(:mergerows) do
    [
      {treatment: "hatch"},
      {treatment: "adopted"},
      {treatment: "hatch"},
      {treatment: "adopted"},
      {treatment: "deworm"}
    ]
  end
  let(:klass) { described_class.new(conditions: conditions) }

  describe "#call" do
    let(:result) { klass.call(origrow: origrow, mergerows: mergerows) }

    context "when using only mergerows" do
      let(:conditions) do
        ->(origrow, mergerows) { [mergerows.first] }
      end

      it "returns expected row(s)" do
        expected = [
          {treatment: "hatch"}
        ]
        expect(result).to eq(expected)
      end
    end

    context "when using orig and mergerows" do
      let(:conditions) do
        ->(origrow, mergerows) {
          mergerows.select { |row|
            row[:treatment] == origrow[:source]
          }
        }
      end

      it "returns expected row(s)" do
        expected = [
          {treatment: "adopted"},
          {treatment: "adopted"}
        ]
        expect(result).to eq(expected)
      end
    end

    context "when using orig only" do
      let(:mergerows) { [] }
      let(:conditions) do
        ->(orig, merge) { return [orig] if merge.empty? }
      end

      it "returns expected row(s)" do
        expected = [
          {source: "adopted"}
        ]
        expect(result).to eq(expected)
      end
    end
  end
end
