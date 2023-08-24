# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::FilterRows::FieldPopulated do
  let(:field) { :val }
  let(:input) do
    [
      {val: "N"},
      {val: "n"},
      {val: "NN"},
      {val: "NY"},
      {val: ""},
      {val: nil}
    ]
  end
  let(:transform) { described_class.new(action: action, field: field) }
  let(:result) { input.map { |row| transform.process(row) }.compact }

  context "with action: :keep" do
    let(:action) { :keep }
    let(:expected) do
      [
        {val: "N"},
        {val: "n"},
        {val: "NN"},
        {val: "NY"}
      ]
    end

    it "transforms as expected" do
      expect(result).to eq(expected)
    end
  end

  context "with action: :reject" do
    let(:action) { :reject }
    let(:expected) do
      [
        {val: ""},
        {val: nil}
      ]
    end

    it "transforms as expected" do
      expect(result).to eq(expected)
    end
  end
end
