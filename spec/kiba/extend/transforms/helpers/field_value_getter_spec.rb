# frozen_string_literal: true

RSpec.describe Kiba::Extend::Transforms::Helpers::FieldValueGetter do
  subject(:checker) { described_class.new(**params) }

  describe "#call" do
    let(:result) { checker.call(row) }
    let(:delim) { "|" }
    let(:fields) { %i[a b c d e f g] }

    let(:row) do
      {
        a: nil,
        b: "",
        c: "|",
        d: "foo",
        e: "%NULLVALUE%",
        f: "%NULLVALUE%|%NULLVALUE%",
        g: "%NULL%|%NULLVALUE%"
      }
    end

    context "with defaults" do
      let(:params) { {fields: fields, delim: delim} }
      let(:expected) do
        {
          d: "foo",
          e: "%NULLVALUE%",
          f: "%NULLVALUE%|%NULLVALUE%",
          g: "%NULL%|%NULLVALUE%"
        }
      end

      it "returns expected values" do
        expect(result).to eq(expected)
      end
    end

    context "with treat_as_null = %NULLVALUE%" do
      let(:params) {
        {fields: fields, delim: delim, treat_as_null: "%NULLVALUE%"}
      }
      let(:expected) do
        {
          d: "foo",
          g: "%NULL%|%NULLVALUE%"
        }
      end

      it "returns expected values" do
        expect(result).to eq(expected)
      end
    end

    context "with treat_as_null = [%NULL%, %NULLVALUE%]" do
      let(:params) {
        {fields: fields, delim: delim, treat_as_null: ["%NULL%", "%NULLVALUE%"]}
      }
      let(:expected) do
        {
          d: "foo"
        }
      end

      it "returns expected values" do
        expect(result).to eq(expected)
      end
    end

    context "with discard = [] and treat_as_null = [%NULL%, %NULLVALUE%]" do
      let(:params) {
        {fields: fields, delim: delim, discard: [],
         treat_as_null: ["%NULL%", "%NULLVALUE%"]}
      }
      let(:expected) do
        {
          a: nil,
          b: "",
          c: "|",
          d: "foo",
          e: "%NULLVALUE%",
          f: "%NULLVALUE%|%NULLVALUE%",
          g: "%NULL%|%NULLVALUE%"
        }
      end

      it "returns expected values" do
        expect(result).to eq(expected)
      end
    end

    context "with discard = [:nil] and treat_as_null = [%NULL%, %NULLVALUE%]" do
      let(:params) {
        {fields: fields, delim: delim, discard: [:nil],
         treat_as_null: ["%NULL%", "%NULLVALUE%"]}
      }
      let(:expected) do
        {
          b: "",
          c: "|",
          d: "foo",
          e: "%NULLVALUE%",
          f: "%NULLVALUE%|%NULLVALUE%",
          g: "%NULL%|%NULLVALUE%"
        }
      end

      it "returns expected values" do
        expect(result).to eq(expected)
      end
    end

    # rubocop:todo Layout/LineLength
    context "with discard = [:empty] and treat_as_null = [%NULL%, %NULLVALUE%]" do
      # rubocop:enable Layout/LineLength
      let(:params) {
        {fields: fields, delim: delim, discard: [:empty],
         treat_as_null: ["%NULL%", "%NULLVALUE%"]}
      }
      let(:expected) do
        {
          a: nil,
          c: "|",
          d: "foo",
          f: "%NULLVALUE%|%NULLVALUE%",
          g: "%NULL%|%NULLVALUE%"
        }
      end

      it "returns expected values" do
        expect(result).to eq(expected)
      end
    end

    # rubocop:todo Layout/LineLength
    context "with discard = [:delim] and treat_as_null = [%NULL%, %NULLVALUE%]" do
      # rubocop:enable Layout/LineLength
      let(:params) {
        {fields: fields, delim: delim, discard: [:delim],
         treat_as_null: ["%NULL%", "%NULLVALUE%"]}
      }
      let(:expected) do
        {
          a: nil,
          b: "",
          d: "foo",
          e: "%NULLVALUE%"
        }
      end

      it "returns expected values" do
        expect(result).to eq(expected)
      end
    end
  end
end
