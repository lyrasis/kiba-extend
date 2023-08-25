# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::Warn::UnevenFields do
  subject(:xform) { described_class.new(fields: fields, delim: delim) }
  let(:fields) { %i[foo bar baz] }
  let(:delim) { "|" }

  describe "#call" do
    let(:result) { xform.process(row) }

    context "with even field values" do
      let(:row) { {foo: "a", bar: "b", baz: "z"} }

      it "returns :even" do
        expect(result).to eq(row)
        expect(xform).not_to receive(:warn)
      end
    end

    context "with uneven field values" do
      let(:row) { {foo: "a|a|a", bar: "b|b", baz: "z"} }

      it "warns and returns row" do
        expect(xform).to receive(:warn)
        expect(result).to eq(row)
      end
    end
  end
end
