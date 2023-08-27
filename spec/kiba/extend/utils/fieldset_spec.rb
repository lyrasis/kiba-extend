# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Utils::Fieldset do
  let(:rows) do
    [
      {a: "aa", b: "bb", c: "cc", d: "dd"},
      {a: "aa", b: nil, c: "cee", d: "dd"},
      {a: "aa", b: "bee", c: "cee", d: "dd"},
      {a: "aa", b: nil, c: "", d: "dd"}
    ]
  end
  let(:fields) { %i[b c] }
  let(:fieldset) { described_class.new(fields: fields) }
  describe "#fields" do
    it "returns an Array of fields collated by the Fieldset" do
      expect(fieldset.fields).to eq(fields)
    end
  end

  describe "#populate" do
    let(:result) { fieldset.populate(rows).hash }

    it "populates hash with field values from given rows" do
      expected = [["bb", nil, "bee"], %w[cc cee cee]]
      expect(result.values).to eq(expected)
    end

    context "with nil rows" do
      let(:rows) { nil }

      it "returns empty field arrays" do
        expected = {b: [], c: []}
        expect(result).to eq(expected)
      end
    end
  end

  describe "#add_constant_values" do
    it "populates hash with constant values" do
      fieldset.populate(rows)
      fieldset.add_constant_values(:f, "ffff")
      expected = [["bb", nil, "bee"], %w[cc cee cee], %w[ffff ffff ffff]]
      expect(fieldset.hash.values).to eq(expected)
    end

    it "adds field, but does not add constant values to it for empty rows" do
      rows = [
        {a: "aa"},
        {a: "aa", b: "bb", c: "cc"},
        {a: "aa", b: ""}
      ]
      fieldset.populate(rows)
      fieldset.add_constant_values(:f, "ffff")
      expected = [["bb"], ["cc"], ["ffff"]]
      expect(fieldset.hash.values).to eq(expected)
    end
  end

  describe "#join_values" do
    it "joins hash values" do
      fieldset.populate(rows)
      fieldset.add_constant_values(:f, "ffff")
      fieldset.join_values("|")
      expected = ["bb||bee", "cc|cee|cee", "ffff|ffff|ffff"]
      expect(fieldset.hash.values).to eq(expected)
    end

    context "with null_placeholder set" do
      let(:fieldset) do
        described_class.new(fields: fields, null_placeholder: "NULL")
      end

      it "joins hash values" do
        fieldset.populate(rows)
        fieldset.add_constant_values(:f, "ffff")
        fieldset.join_values("|")
        expected = ["bb|NULL|bee", "cc|cee|cee", "ffff|ffff|ffff"]
        expect(fieldset.hash.values).to eq(expected)
      end
    end
  end
end
