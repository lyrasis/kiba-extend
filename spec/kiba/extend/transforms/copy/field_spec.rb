# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::Copy::Field do
  let(:input) do
    [
      {name: "Weddy", sex: "m"},
      {name: "Kernel", sex: "f"},
      {name: "keet", sex: ""},
      {name: "keet", sex: nil}
    ]
  end

  let(:transform) { described_class.new(from: :sex, to: :gender) }

  let(:expected) do
    [
      {name: "Weddy", sex: "m", gender: "m"},
      {name: "Kernel", sex: "f", gender: "f"},
      {name: "keet", sex: "", gender: ""},
      {name: "keet", sex: nil, gender: nil}
    ]
  end

  let(:result) { input.map { |row| transform.process(row) } }

  it "copies value of field to specified new field" do
    expect(result).to eq(expected)
  end

  context "when from field does not exist" do
    let(:transform) { described_class.new(from: :foo, to: :gender) }

    it "copies value of field to specified new field" do
      # rubocop:todo Layout/LineLength
      msg = "Cannot copy from nonexistent field `foo`\nExisting fields: name, sex"
      # rubocop:enable Layout/LineLength
      expect {
        result
        # rubocop:todo Layout/LineLength
      }.to raise_error(Kiba::Extend::Transforms::Copy::Field::MissingFromFieldError).with_message(msg)
      # rubocop:enable Layout/LineLength
    end
  end
end
