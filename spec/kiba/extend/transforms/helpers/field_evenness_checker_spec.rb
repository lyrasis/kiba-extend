# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::Helpers::FieldEvennessChecker do
  subject(:checker) { described_class.new(fields: fields, delim: delim) }
  let(:fields) { %i[foo bar baz] }
  let(:delim) { "|" }

  describe "#call" do
    let(:result) { checker.call(row) }

    context "with even field values" do
      let(:row) { {foo: "a", bar: "b", baz: "z"} }

      it "returns :even" do
        expect(result).to eq(:even)
      end
    end

    context "with even field values except for nil/empty" do
      let(:row) { {foo: "a", bar: "", baz: nil} }

      it "returns :even" do
        expect(result).to eq(:even)
      end
    end

    context "with uneven field values" do
      let(:row) { {foo: "a|a|a", bar: "b|b", baz: "z"} }

      it "returns Hash of uneven fieldnames/values" do
        expect(result).to eq({bar: "b|b", baz: "z"})
      end
    end
  end
end
