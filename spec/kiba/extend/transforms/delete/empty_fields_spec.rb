# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::Delete::EmptyFields do
  let(:accumulator) { [] }
  let(:test_job) do
    Helpers::TestJob.new(input: input, accumulator: accumulator,
      transforms: transforms)
  end
  let(:result) { test_job.accumulator }

  let(:input) do
    [
      {a: "a", b: "", c: "ccc", d: ""},
      {a: "", b: nil, c: "c", d: nil},
      {a: nil, b: "", c: "ccc", d: ""},
      {a: "a", b: "", c: "", d: ""}
    ]
  end

  let(:expected) do
    [
      {a: "a", c: "ccc"},
      {a: "", c: "c"},
      {a: nil, c: "ccc"},
      {a: "a", c: ""}
    ]
  end

  let(:transforms) do
    Kiba.job_segment do
      transform Delete::EmptyFields
    end
  end

  it "transforms as expected" do
    expect(result).to eq(expected)
  end

  context "with usenull true" do
    let(:input) do
      [
        {a: "", b: nil, c: "c", d: nil, e: "%NULLVALUE%"},
        {a: "a", b: "", c: "ccc", d: "", e: ""},
        {a: nil, b: "", c: "ccc", d: "", e: "%NULLVALUE%"},
        {a: "a", b: "", c: "", d: "", e: ""}
      ]
    end

    let(:expected) do
      [
        {a: "", c: "c"},
        {a: "a", c: "ccc"},
        {a: nil, c: "ccc"},
        {a: "a", c: ""}
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Delete::EmptyFields, usenull: true
      end
    end

    it "transforms as expected" do
      expect(result).to eq(expected)
    end
  end

  context "with consider_blank config" do
    let(:input) do
      [
        {a: "", b: nil, c: "", d: nil, e: "0"},
        {a: "a", b: "", c: "%NULLVALUE%", d: "", e: "false"},
        {a: nil, b: "false", c: "nope", d: "", e: "0"},
        {a: "a", b: "", c: nil, d: "", e: ""}
      ]
    end

    let(:expected) do
      [
        {a: "", c: ""},
        {a: "a", c: "%NULLVALUE%"},
        {a: nil, c: "nope"},
        {a: "a", c: nil}
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Delete::EmptyFields,
          consider_blank: {b: "false", c: "nope",
                           e: "0#{Kiba::Extend.delim}false"}
      end
    end

    it "transforms as expected" do
      expect(result).to eq(expected)
    end

    context "with usenull true" do
      let(:expected) do
        [
          {a: ""},
          {a: "a"},
          {a: nil},
          {a: "a"}
        ]
      end

      let(:transforms) do
        Kiba.job_segment do
          transform Delete::EmptyFields, usenull: true,
            # rubocop:todo Layout/LineLength
            consider_blank: {b: "false", c: "nope", e: "0#{Kiba::Extend.delim}false"}
          # rubocop:enable Layout/LineLength
        end
      end

      it "transforms as expected" do
        expect(result).to eq(expected)
      end
    end
  end

  context "with empty input source" do
    let(:input) { [] }

    let(:expected) { [] }

    let(:transforms) do
      Kiba.job_segment do
        transform Delete::EmptyFields
      end
    end

    it "transforms as expected" do
      expect(result).to eq(expected)
    end
  end
end
