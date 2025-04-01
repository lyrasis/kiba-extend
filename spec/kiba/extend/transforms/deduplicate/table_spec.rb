# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::Deduplicate::Table do
  subject(:xform) { described_class.new(**params) }
  let(:params) { {field: field} }
  let(:field) { :combined }
  let(:result) do
    Kiba::StreamingRunner.transform_stream(input, xform)
      .map { |row| row }
  end

  let(:input) do
    [
      {foo: "a", bar: "b", baz: "f", combined: "a b"},
      {foo: "c", bar: "d", baz: "g", combined: "c d"},
      {foo: "c", bar: "e", baz: "h", combined: "c e"},
      {foo: "c", bar: "d", baz: "i", combined: "c d"},
      {foo: "c", bar: "d", baz: "j", combined: "c d"},
      {foo: "c", bar: "d", baz: "k", combined: "c d"}
    ]
  end

  context "when keeping deduplication field" do
    let(:field) { :foo }
    let(:expected) do
      [
        {foo: "a", bar: "b", baz: "f", combined: "a b"},
        {foo: "c", bar: "d", baz: "g", combined: "c d"}
      ]
    end

    it "deduplicates table, retaining field" do
      expect(result).to eq(expected)
    end
  end

  context "when deleting deduplication field" do
    let(:params) { {field: field, delete_field: true} }
    let(:field) { :combined }
    let(:expected) do
      [
        {foo: "a", bar: "b", baz: "f"},
        {foo: "c", bar: "d", baz: "g"},
        {foo: "c", bar: "e", baz: "h"}
      ]
    end

    it "deletes deduplication field" do
      expect(result).to eq(expected)
    end
  end

  context "when gathering examples" do
    let(:params) do
      {field: field, delete_field: true, example_source_field: :baz,
       max_examples: 3, example_target_field: :ex, example_delim: " ; "}
    end
    let(:field) { :combined }
    let(:expected) do
      [
        {foo: "a", bar: "b", baz: "f", ex: "f"},
        {foo: "c", bar: "d", baz: "g", ex: "g ; i ; j"},
        {foo: "c", bar: "e", baz: "h", ex: "h"}
      ]
    end

    it "adds example field" do
      expect(result).to eq(expected)
    end
  end

  context "when returning occurrence count" do
    let(:params) do
      {field: field, delete_field: true, example_source_field: :baz,
       max_examples: 3, example_target_field: :ex, include_occs: true}
    end
    let(:field) { :combined }
    let(:expected) do
      [
        {foo: "a", bar: "b", baz: "f", occurrences: 1, ex: "f"},
        {foo: "c", bar: "d", baz: "g", occurrences: 4, ex: "g|i|j"},
        {foo: "c", bar: "e", baz: "h", occurrences: 1, ex: "h"}
      ]
    end

    it "adds occurrence field" do
      expect(result).to eq(expected)
    end
  end
end
