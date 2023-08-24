# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::Delete::EmptyFieldGroups do
  subject(:xform) { described_class.new(**params) }
  let(:params) { {groups: groups, delim: delim} }
  let(:groups) { [%i[aa ab], %i[bb bc bd]] }
  let(:delim) { "|" }
  let(:result) { input.map { |row| xform.process(row) } }
  let(:input) do
    [
      {aa: "", ab: "", bb: "", bc: "", bd: ""},
      {aa: "n|", ab: nil, bb: "|e", bc: "|n", bd: "|e"},
      {aa: "n", ab: "", bb: "n", bc: "e", bd: "p"},
      {aa: "n|e", ab: "e|n", bb: "n|e", bc: "e|n", bd: "ne|"},
      {aa: "n|", ab: "e|", bb: "|e", bc: "n|e", bd: "|e"},
      {aa: "|", ab: "|", bb: "e||n|", bc: "n||e|", bd: "e||p|"},
      {aa: "%NULLVALUE%", ab: "%NULLVALUE%", bb: "%NULLVALUE%|%NULLVALUE%",
       bc: nil, bd: "|"},
      {aa: "|", ab: "", bb: "%NULLVALUE%|", bc: "%NULLVALUE%|%NULLVALUE%",
       bd: "%NULLVALUE%|a"},
      {aa: "|", ab: "", bb: "%NULLVALUE%|", bc: "%NULLVALUE%|NULL",
       bd: "%NULLVALUE%|a"}
    ]
  end

  context "with defaults (treat_as_empty: %NULLVALUE%)" do
    let(:expected) do
      [
        {aa: nil, ab: nil, bb: nil, bc: nil, bd: nil},
        {aa: "n", ab: nil, bb: "e", bc: "n", bd: "e"},
        {aa: "n", ab: nil, bb: "n", bc: "e", bd: "p"},
        {aa: "n|e", ab: "e|n", bb: "n|e", bc: "e|n", bd: "ne|"},
        {aa: "n", ab: "e", bb: "|e", bc: "n|e", bd: "|e"},
        {aa: nil, ab: nil, bb: "e|n", bc: "n|e", bd: "e|p"},
        {aa: nil, ab: nil, bb: nil, bc: nil, bd: nil},
        {aa: nil, ab: nil, bb: nil, bc: nil, bd: "a"},
        {aa: nil, ab: nil, bb: nil, bc: "NULL", bd: "a"}
      ]
    end

    it "deletes as expected" do
      expect(result).to eq(expected)
    end
  end

  context "with array of treat_as_empty values: [%NULLVALUE%, NULL]" do
    let(:params) {
      {groups: groups, delim: delim, treat_as_null: ["NULL", "%NULLVALUE%"]}
    }
    let(:expected) do
      [
        {aa: nil, ab: nil, bb: nil, bc: nil, bd: nil},
        {aa: "n", ab: nil, bb: "e", bc: "n", bd: "e"},
        {aa: "n", ab: nil, bb: "n", bc: "e", bd: "p"},
        {aa: "n|e", ab: "e|n", bb: "n|e", bc: "e|n", bd: "ne|"},
        {aa: "n", ab: "e", bb: "|e", bc: "n|e", bd: "|e"},
        {aa: nil, ab: nil, bb: "e|n", bc: "n|e", bd: "e|p"},
        {aa: nil, ab: nil, bb: nil, bc: nil, bd: nil},
        {aa: nil, ab: nil, bb: nil, bc: nil, bd: "a"},
        {aa: nil, ab: nil, bb: nil, bc: nil, bd: "a"}
      ]
    end

    it "deletes as expected" do
      expect(result).to eq(expected)
    end
  end

  context "with treat_as_empty: nil" do
    let(:params) { {groups: groups, delim: delim, treat_as_null: nil} }
    let(:expected) do
      [
        {aa: nil, ab: nil, bb: nil, bc: nil, bd: nil},
        {aa: "n", ab: nil, bb: "e", bc: "n", bd: "e"},
        {aa: "n", ab: nil, bb: "n", bc: "e", bd: "p"},
        {aa: "n|e", ab: "e|n", bb: "n|e", bc: "e|n", bd: "ne|"},
        {aa: "n", ab: "e", bb: "|e", bc: "n|e", bd: "|e"},
        {aa: nil, ab: nil, bb: "e|n", bc: "n|e", bd: "e|p"},
        {aa: "%NULLVALUE%", ab: "%NULLVALUE%", bb: "%NULLVALUE%|%NULLVALUE%",
         bc: nil, bd: nil},
        {aa: nil, ab: nil, bb: "%NULLVALUE%|", bc: "%NULLVALUE%|%NULLVALUE%",
         bd: "%NULLVALUE%|a"},
        {aa: nil, ab: nil, bb: "%NULLVALUE%|", bc: "%NULLVALUE%|NULL",
         bd: "%NULLVALUE%|a"}
      ]
    end

    it "deletes as expected" do
      expect(result).to eq(expected)
    end
  end
end
