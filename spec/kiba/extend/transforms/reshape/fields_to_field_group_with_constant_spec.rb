# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Layout/LineLength
RSpec.describe Kiba::Extend::Transforms::Reshape::FieldsToFieldGroupWithConstant do
  # rubocop:enable Layout/LineLength
  subject(:xform) { described_class.new(**params) }
  let(:delim) { "|" }
  let(:result) { input.map { |row| xform.process(row) } }
  let(:input) do
    [
      {note: "foo", date: "2022"},
      {note: nil, date: "2022"},
      {note: "foo", date: nil},
      {note: "", date: nil},
      {note: "foo|bar|baz", date: "2022|2021"},
      {note: "foo|bar", date: nil},
      {note: "foo|bar|baz", date: "2022||2021"},
      {note: "|bar|baz", date: "2022|2021"},
      {note: "foo|bar|", date: "2022|2021"}
    ]
  end

  context "with defaults" do
    let(:params) do
      {
        fieldmap: {note: :a_note, date: :a_date},
        constant_target: :a_type,
        constant_value: "a thing"
      }
    end

    let(:expected) do
      [
        {a_type: "a thing", a_note: "foo", a_date: "2022"},
        {a_type: "a thing", a_note: nil, a_date: "2022"},
        {a_type: "a thing", a_note: "foo", a_date: nil},
        {a_type: nil, a_note: "", a_date: nil},
        {a_type: "a thing|a thing|a thing", a_note: "foo|bar|baz",
         a_date: "2022|2021|%NULLVALUE%"},
        {a_type: "a thing|a thing", a_note: "foo|bar", a_date: nil},
        {a_type: "a thing|a thing|a thing", a_note: "foo|bar|baz",
         a_date: "2022|%NULLVALUE%|2021"},
        {a_type: "a thing|a thing|a thing", a_note: "%NULLVALUE%|bar|baz",
         a_date: "2022|2021|%NULLVALUE%"},
        {a_type: "a thing|a thing|a thing", a_note: "foo|bar|%NULLVALUE%",
         a_date: "2022|2021|%NULLVALUE%"}
      ]
    end

    it "reshapes the columns as specified" do
      expect(result).to eq(expected)
    end

    context "with only one fieldmap field" do
      let(:input) do
        [
          {note: "foo"},
          {note: nil},
          {note: "bar|foo"}
        ]
      end
      let(:params) do
        {
          fieldmap: {note: :a_note},
          constant_target: :a_type,
          constant_value: "a thing"
        }
      end

      let(:expected) do
        [
          {a_type: "a thing", a_note: "foo"},
          {a_type: nil, a_note: nil},
          {a_type: "a thing|a thing", a_note: "bar|foo"}
        ]
      end

      it "reshapes the columns as specified" do
        expect(result).to eq(expected)
      end
    end
  end

  context "with `treat_as_null: %BLANK%`" do
    let(:params) do
      {
        fieldmap: {note: :a_note, date: :a_date},
        constant_target: :a_type,
        constant_value: "a thing",
        treat_as_null: "%BLANK%"
      }
    end

    let(:expected) do
      [
        {a_type: "a thing", a_note: "foo", a_date: "2022"},
        {a_type: "a thing", a_note: nil, a_date: "2022"},
        {a_type: "a thing", a_note: "foo", a_date: nil},
        {a_type: nil, a_note: "", a_date: nil},
        {a_type: "a thing|a thing|a thing", a_note: "foo|bar|baz",
         a_date: "2022|2021|%BLANK%"},
        {a_type: "a thing|a thing", a_note: "foo|bar", a_date: nil},
        {a_type: "a thing|a thing|a thing", a_note: "foo|bar|baz",
         a_date: "2022|%BLANK%|2021"},
        {a_type: "a thing|a thing|a thing", a_note: "%BLANK%|bar|baz",
         a_date: "2022|2021|%BLANK%"},
        {a_type: "a thing|a thing|a thing", a_note: "foo|bar|%BLANK%",
         a_date: "2022|2021|%BLANK%"}
      ]
    end

    it "reshapes the columns as specified" do
      expect(result).to eq(expected)
    end
  end

  context "with `evener: :value`" do
    let(:params) do
      {
        fieldmap: {note: :a_note, date: :a_date},
        constant_target: :a_type,
        constant_value: "a thing",
        evener: :value
      }
    end

    let(:expected) do
      [
        {a_type: "a thing", a_note: "foo", a_date: "2022"},
        {a_type: "a thing", a_note: nil, a_date: "2022"},
        {a_type: "a thing", a_note: "foo", a_date: nil},
        {a_type: nil, a_note: "", a_date: nil},
        {a_type: "a thing|a thing|a thing", a_note: "foo|bar|baz",
         a_date: "2022|2021|2021"},
        {a_type: "a thing|a thing", a_note: "foo|bar", a_date: nil},
        {a_type: "a thing|a thing|a thing", a_note: "foo|bar|baz",
         a_date: "2022|%NULLVALUE%|2021"},
        {a_type: "a thing|a thing|a thing", a_note: "%NULLVALUE%|bar|baz",
         a_date: "2022|2021|2021"},
        {a_type: "a thing|a thing|a thing", a_note: "foo|bar|%NULLVALUE%",
         a_date: "2022|2021|2021"}
      ]
    end

    it "reshapes the columns as specified" do
      expect(result).to eq(expected)
    end
  end

  context "with `enforce_evenness: false`" do
    let(:params) do
      {
        fieldmap: {note: :a_note, date: :a_date},
        constant_target: :a_type,
        constant_value: "a thing",
        enforce_evenness: false
      }
    end

    let(:expected) do
      [
        {a_type: "a thing", a_note: "foo", a_date: "2022"},
        {a_type: "a thing", a_note: nil, a_date: "2022"},
        {a_type: "a thing", a_note: "foo", a_date: nil},
        {a_type: nil, a_note: "", a_date: nil},
        {a_type: "a thing|a thing|a thing", a_note: "foo|bar|baz",
         a_date: "2022|2021"},
        {a_type: "a thing|a thing", a_note: "foo|bar", a_date: nil},
        {a_type: "a thing|a thing|a thing", a_note: "foo|bar|baz",
         a_date: "2022|%NULLVALUE%|2021"},
        {a_type: "a thing|a thing|a thing", a_note: "%NULLVALUE%|bar|baz",
         a_date: "2022|2021"},
        {a_type: "a thing|a thing|a thing", a_note: "foo|bar|%NULLVALUE%",
         a_date: "2022|2021"}
      ]
    end

    it "reshapes the columns as specified" do
      expect(result).to eq(expected)
    end
  end

  context "with `treat_as_null: nil` and `evener: %NULL%`" do
    let(:params) do
      {
        fieldmap: {note: :a_note, date: :a_date},
        constant_target: :a_type,
        constant_value: "a thing",
        treat_as_null: nil,
        evener: "%NULL%"
      }
    end

    let(:expected) do
      [
        {a_type: "a thing", a_note: "foo", a_date: "2022"},
        {a_type: "a thing", a_note: nil, a_date: "2022"},
        {a_type: "a thing", a_note: "foo", a_date: nil},
        {a_type: nil, a_note: "", a_date: nil},
        {a_type: "a thing|a thing|a thing", a_note: "foo|bar|baz",
         a_date: "2022|2021|%NULL%"},
        {a_type: "a thing|a thing", a_note: "foo|bar", a_date: nil},
        {a_type: "a thing|a thing|a thing", a_note: "foo|bar|baz",
         a_date: "2022||2021"},
        {a_type: "a thing|a thing|a thing", a_note: "|bar|baz",
         a_date: "2022|2021|%NULL%"},
        {a_type: "a thing|a thing|a thing", a_note: "foo|bar|",
         a_date: "2022|2021|%NULL%"}
      ]
    end

    it "reshapes the columns as specified" do
      expect(result).to eq(expected)
    end
  end

  context "with single source field" do
    let(:input) do
      [
        {note: "foo"},
        {note: nil},
        {note: ""},
        {note: "foo|bar"}
      ]
    end

    let(:params) do
      {
        fieldmap: {note: :a_note},
        constant_target: :a_type,
        constant_value: "a thing",
        replace_empty: false
      }
    end

    let(:expected) do
      [
        {a_type: "a thing", a_note: "foo"},
        {a_type: nil, a_note: nil},
        {a_type: nil, a_note: ""},
        {a_type: "a thing|a thing", a_note: "foo|bar"}
      ]
    end

    it "reshapes the columns as specified" do
      expect(result).to eq(expected)
    end
  end
end
