# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::FilterRows::WithLambda do
  let(:input) do
    [
      {a: "a", b: "b", c: "c"},
      {a: "a", b: "b", c: ""},
      {a: "", b: nil, c: "c"},
      {a: "", b: "b", c: "c"},
      {a: "", b: nil, c: nil}
    ]
  end
  let(:action) { :keep }
  let(:lambda) { ->(row) { row.values.any?(nil) } }
  let(:transform) { described_class.new(action: action, lambda: lambda) }
  let(:result) { input.map { |row| transform.process(row) }.compact }

  context "with action: :keep" do
    let(:expected) do
      [
        {a: "", b: nil, c: "c"},
        {a: "", b: nil, c: nil}
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
        {a: "a", b: "b", c: "c"},
        {a: "a", b: "b", c: ""},
        {a: "", b: "b", c: "c"}
      ]
    end

    it "transforms as expected" do
      expect(result).to eq(expected)
    end
  end

  context "when lambda does not eval to true/false" do
    let(:row) { {a: "", b: nil, c: "c"} }
    let(:lambda) { ->(row) { row.values.select { |val| val.nil? } } }
    it "raises error" do
      expect { transform.process(row) }.to raise_error(
        Kiba::Extend::BooleanReturningLambdaError
      )
    end
  end
end
