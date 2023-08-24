# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Utils::Lookup::PairInclusion do
  describe "checks if row value contains basic string values" do
    context "when row field value contains string value" do
      it "returns true" do
        obj = Lookup::PairInclusion.new(
          pair: ["row::a", "value::bcd"],
          row: {a: "abcdef"}
        )
        expect(obj.result).to be true
      end
    end

    context "when row field value does not contain string value" do
      it "returns false" do
        obj = Lookup::PairInclusion.new(
          pair: ["row::a", "value::abc"],
          row: {a: "a"}
        )
        expect(obj.result).to be false
      end
    end
  end

  describe "checks if row values match regexp values" do
    context "when row field value matches regexp value" do
      it "returns true" do
        obj = Lookup::PairInclusion.new(
          pair: ["row::a", "revalue::[Aa].c"],
          row: {a: "zabcy"}
        )
        expect(obj.result).to be true
      end
    end

    context "when row field value does not match regexp value" do
      it "returns false" do
        obj = Lookup::PairInclusion.new(
          pair: ["row::a", "revalue::[Aa].c"],
          row: {a: "abCd"}
        )
        expect(obj.result).to be false
      end
    end

    context "when regexp value explicitly includes ^ and/or $ anchors" do
      it "treats them as expected in a regexp" do
        obj = Lookup::PairInclusion.new(
          pair: ["row::a", "revalue::^[Aa].c$"],
          row: {a: "abc"}
        )
        expect(obj.result).to be true
      end
    end

    context "when row value is nil" do
      it "returns false" do
        obj = Lookup::PairInclusion.new(
          pair: ["row::a", "revalue::^[Aa].c$"],
          row: {a: nil}
        )
        expect(obj.result).to be false
      end
    end
  end

  describe "compares mergerow field values to basic string values" do
    context "when mergerow field value equals string value" do
      it "returns true" do
        obj = Lookup::PairEquality.new(
          pair: ["mergerow::a", "value::abc"],
          row: {b: "def"},
          mergerow: {a: "abc"}
        )
        expect(obj.result).to be true
      end
    end

    context "when mergerow field value not equal to string value" do
      it "returns false" do
        obj = Lookup::PairEquality.new(
          pair: ["mergerow::a", "value::abc"],
          row: {b: "def"},
          mergerow: {a: "ab"}
        )
        expect(obj.result).to be false
      end
    end

    context "when mergerow is not passed to class" do
      it "returns false" do
        obj = Lookup::PairEquality.new(
          pair: ["mergerow::a", "value::abc"],
          row: {b: "def"}
        )
        expect(obj.result).to be false
      end
    end
  end

  describe "compares row field value to mergerow field value" do
    context "when row and mergerow field values are equal" do
      it "returns true" do
        obj = Lookup::PairEquality.new(
          pair: ["mergerow::a", "row::b"],
          row: {b: "abc"},
          mergerow: {a: "abc"}
        )
        expect(obj.result).to be true
      end
    end

    context "when row and mergerow field values are not equal" do
      it "returns false" do
        obj = Lookup::PairEquality.new(
          pair: ["mergerow::a", "row::b"],
          row: {b: "abc"},
          mergerow: {a: "def"}
        )
        expect(obj.result).to be false
      end
    end

    context "when neither row nor mergerow contains its specified field" do
      it "returns true" do
        obj = Lookup::PairEquality.new(
          pair: ["mergerow::a", "row::b"],
          row: {},
          mergerow: {}
        )
        expect(obj.result).to be true
      end
    end

    context "when row field exists but is blank and mergerow field does not exist" do
      it "returns false" do
        obj = Lookup::PairEquality.new(
          pair: ["mergerow::a", "row::b"],
          row: {b: ""},
          mergerow: {}
        )
        expect(obj.result).to be false
      end
    end
  end
end
