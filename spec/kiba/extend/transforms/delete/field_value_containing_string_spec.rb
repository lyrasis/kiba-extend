# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::Delete::FieldValueContainingString do
  let(:accumulator) { [] }
  let(:test_job) {
    Helpers::TestJob.new(input: input, accumulator: accumulator,
      transforms: transforms)
  }
  let(:result) { test_job.accumulator }

  let(:input) do
    [
      {a: "xxxx a thing", b: "foo"},
      {a: "thing xxxx 123", b: "bar"},
      {a: "x thing", b: "xxxx"},
      {a: "y thing", b: "xXxX"},
      {a: "xxxxxxx thing", b: "baz"},
      {a: "", b: nil}
    ]
  end

  let(:transforms) do
    Kiba.job_segment do
      transform Delete::FieldValueContainingString, fields: %i[a b],
        match: "xxxx"
    end
  end

  let(:expected) do
    [
      {a: nil, b: "foo"},
      {a: nil, b: "bar"},
      {a: "x thing", b: nil},
      {a: "y thing", b: "xXxX"},
      {a: nil, b: "baz"},
      {a: "", b: nil}
    ]
  end

  it "transforms as expected" do
    expect(result).to eq(expected)
  end

  context "with casesensitive = false" do
    let(:input) do
      [
        {a: "y thing", b: "xXxXxXy"}
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Delete::FieldValueContainingString, fields: :b,
          match: "xxxx", casesensitive: false
      end
    end

    let(:expected) do
      [
        {a: "y thing", b: nil}
      ]
    end

    it "transforms as expected" do
      expect(result).to eq(expected)
    end
  end
end
