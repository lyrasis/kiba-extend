# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::Replace::EmptyFieldValues do
  subject(:xform) { described_class.new(**params) }
  let(:result) { input.map { |row| xform.process(row) } }
  let(:input) do
    [
      {species: "guineafowl", name: nil, sex: ""},
      {species: "guineafowl", name: "%NULL%", sex: "%NULL%"},
      {species: "guineafowl", name: "Weddy||Grimace|", sex: ""},
      {species: "guineafowl", name: "|Weddy|Grimace|", sex: "%NULL%|m|m|"}
    ]
  end

  context "plain/single value" do
    let(:params) { {fields: %i[name sex], value: "%NULLVALUE%"} }
    let(:expected) do
      [
        {species: "guineafowl", name: "%NULLVALUE%", sex: "%NULLVALUE%"},
        {species: "guineafowl", name: "%NULL%", sex: "%NULL%"},
        {species: "guineafowl", name: "Weddy||Grimace|", sex: "%NULLVALUE%"},
        {species: "guineafowl", name: "|Weddy|Grimace|", sex: "%NULL%|m|m|"}
      ]
    end

    it "replaces empty field values in specified field(s) with given string" do
      expect(result).to eq(expected)
    end
  end

  context "plain/single value with treat_as_null" do
    let(:params) do
      {fields: %i[name sex], value: "%NULLVALUE%", treat_as_null: "%NULL%"}
    end
    let(:expected) do
      [
        {species: "guineafowl", name: "%NULLVALUE%", sex: "%NULLVALUE%"},
        {species: "guineafowl", name: "%NULLVALUE%", sex: "%NULLVALUE%"},
        {species: "guineafowl", name: "Weddy||Grimace|", sex: "%NULLVALUE%"},
        {species: "guineafowl", name: "|Weddy|Grimace|", sex: "%NULL%|m|m|"}
      ]
    end

    it "replaces empty field values in specified field(s) with given string" do
      expect(result).to eq(expected)
    end
  end

  context "multi value" do
    let(:params) { {fields: %i[name sex], value: "%NULLVALUE%", delim: "|"} }
    let(:expected) do
      [
        {species: "guineafowl", name: "%NULLVALUE%", sex: "%NULLVALUE%"},
        {species: "guineafowl", name: "%NULL%", sex: "%NULL%"},
        {species: "guineafowl", name: "Weddy|%NULLVALUE%|Grimace|%NULLVALUE%",
         sex: "%NULLVALUE%"},
        {species: "guineafowl", name: "%NULLVALUE%|Weddy|Grimace|%NULLVALUE%",
         sex: "%NULL%|m|m|%NULLVALUE%"}
      ]
    end

    it "replaces empty field values in specified field(s) with given string" do
      expect(result).to eq(expected)
    end
  end

  context "multi value with treat_as_null" do
    let(:params) do
      {fields: %i[name sex], value: "%NULLVALUE%", delim: "|",
       treat_as_null: "%NULL%"}
    end
    let(:expected) do
      [
        {species: "guineafowl", name: "%NULLVALUE%", sex: "%NULLVALUE%"},
        {species: "guineafowl", name: "%NULLVALUE%", sex: "%NULLVALUE%"},
        {species: "guineafowl", name: "Weddy|%NULLVALUE%|Grimace|%NULLVALUE%",
         sex: "%NULLVALUE%"},
        {species: "guineafowl", name: "%NULLVALUE%|Weddy|Grimace|%NULLVALUE%",
         sex: "%NULLVALUE%|m|m|%NULLVALUE%"}
      ]
    end

    it "replaces empty field values in specified field(s) with given string" do
      expect(result).to eq(expected)
    end
  end

  context "with array of treat_as_nulls" do
    let(:input) { [{species: "guineafowl", name: "%NADA%", sex: "%NULL%"}] }
    let(:params) do
      {fields: %i[name sex], value: "%NULLVALUE%",
       treat_as_null: ["%NADA%", "%NULL%"]}
    end
    let(:expected) do
      [{species: "guineafowl", name: "%NULLVALUE%", sex: "%NULLVALUE%"}]
    end

    it "replaces empty field values in specified field(s) with given string" do
      expect(result).to eq(expected)
    end
  end
end
