# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::Delete::DelimiterOnlyFieldValues do
  subject(:xform) { described_class.new(**params) }
  let(:result) { input.map { |row| xform.process(row) } }
  let(:nv) { Kiba::Extend.nullvalue }
  let(:delim) { "|" }

  let(:input) do
    [
      {foo: "a| b", bar: " | ", baz: ""},
      {foo: nil, bar: "|", baz: " |b"},
      {foo: nv, bar: "#{nv}|#{nv}", baz: "#{nv}| #{nv}"},
      {foo: "NULL", bar: "NULL |#{nv}", baz: "NULL| NULL"}
    ]
  end

  context "with defaults" do
    let(:params) { {fields: :all, delim: delim} }
    let(:expected) do
      [
        {foo: "a| b", bar: nil, baz: nil},
        {foo: nil, bar: nil, baz: " |b"},
        {foo: nv, bar: "#{nv}|#{nv}", baz: "#{nv}| #{nv}"},
        {foo: "NULL", bar: "NULL |#{nv}", baz: "NULL| NULL"}
      ]
    end
    it "deletes as expected" do
      expect(result).to eq(expected)
    end
  end

  context "with `treat_as_null: default nullvalue`" do
    let(:params) { {fields: :all, delim: delim, treat_as_null: nv} }
    let(:expected) do
      [
        {foo: "a| b", bar: nil, baz: nil},
        {foo: nil, bar: nil, baz: " |b"},
        {foo: nil, bar: nil, baz: nil},
        {foo: "NULL", bar: "NULL |#{nv}", baz: "NULL| NULL"}
      ]
    end
    it "deletes as expected" do
      expect(result).to eq(expected)
    end
  end

  # Tests that whole values are looked at and it isn't going to do
  #   weird replacements and mess up unintended data
  context "with `treat_as_null: NULL`" do
    let(:params) { {fields: :all, delim: delim, treat_as_null: "NULL"} }
    let(:expected) do
      [
        {foo: "a| b", bar: nil, baz: nil},
        {foo: nil, bar: nil, baz: " |b"},
        {foo: nv, bar: "#{nv}|#{nv}", baz: "#{nv}| #{nv}"},
        {foo: nil, bar: "NULL |#{nv}", baz: nil}
      ]
    end
    it "deletes as expected" do
      expect(result).to eq(expected)
    end
  end

  context "with `treat_as_null: array of strings`" do
    let(:params) { {fields: :all, delim: delim, treat_as_null: ["NULL", nv]} }
    let(:expected) do
      [
        {foo: "a| b", bar: nil, baz: nil},
        {foo: nil, bar: nil, baz: " |b"},
        {foo: nil, bar: nil, baz: nil},
        {foo: nil, bar: nil, baz: nil}
      ]
    end
    it "deletes as expected" do
      expect(result).to eq(expected)
    end
  end
end
