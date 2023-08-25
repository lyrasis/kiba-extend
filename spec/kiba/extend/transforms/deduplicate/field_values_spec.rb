# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::Deduplicate::FieldValues do
  subject(:xform) { described_class.new(fields: fields, sep: sep) }
  let(:fields) { %i[foo bar] }
  let(:sep) { ";" }
  let(:result) { input.map { |row| xform.process(row) } }

  let(:input) do
    [
      {foo: "1;1;1;2;2;2", bar: "a;A;b;b;b"},
      {foo: "", bar: "q;r;r"},
      {foo: "1", bar: "2"},
      {foo: 1, bar: 2}
    ]
  end

  let(:expected) do
    [
      {foo: "1;2", bar: "a;A;b"},
      {foo: "", bar: "q;r"},
      {foo: "1", bar: "2"},
      {foo: "1", bar: "2"}
    ]
  end

  it "deduplicates values in each field" do
    expect(result).to eq(expected)
  end
end
