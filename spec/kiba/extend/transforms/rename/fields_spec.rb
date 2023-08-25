# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::Rename::Fields do
  let(:fieldmap) { {name: :appellation, sex: :gender} }
  let(:transform) { Rename::Fields.new(fieldmap: fieldmap) }
  let(:results) { rows.map { |row| transform.process(row) } }

  context "when target field exists" do
    let(:rows) do
      [
        {name: "Weddy", sex: "m"},
        {name: "Kernel", sex: "f"}
      ]
    end

    let(:expected) do
      [
        {appellation: "Weddy", gender: "m"},
        {appellation: "Kernel", gender: "f"}
      ]
    end

    it "renames fields" do
      expect(results).to eq(expected)
    end
  end

  context "when target field does not exist" do
    let(:rows) do
      [
        {name: "Weddy"}
      ]
    end

    let(:expected) do
      [
        {appellation: "Weddy"}
      ]
    end

    it "returns row unchanged and warns", :aggregate_failures do
      # rubocop:todo Layout/LineLength
      msg = "#{Kiba::Extend.warning_label}: Cannot rename field: `sex` does not exist in row"
      # rubocop:enable Layout/LineLength
      expect_any_instance_of(Rename::Field).to receive(:warn).with(msg)
      expect(results).to eq(expected)
    end
  end
end
