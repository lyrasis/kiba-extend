# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::FilterRows::FieldMatchRegexp do
  let(:field) { :val }
  let(:match) { "^N" }
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
  let(:transform) {
    described_class.new(action: action, field: field, match: match)
  }
  let(:result) { input.map { |row| transform.process(row) }.compact }

  context "with action: :keep" do
    let(:action) { :keep }
    let(:expected) do
      [
        {val: "N"},
        {val: "NN"},
        {val: "NY"}
      ]
    end

    it "transforms as expected" do
      expect(result).to eq(expected)
    end

    context "with case insensitive flag" do
      let(:transform) {
        described_class.new(action: action, field: field, match: match,
          ignore_case: true)
      }
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
  end

  context "with action: :reject" do
    let(:action) { :reject }
    let(:expected) do
      [
        {val: "n"},
        {val: ""},
        {val: nil}
      ]
    end

    it "transforms as expected" do
      expect(result).to eq(expected)
    end
  end
end
