# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::Append do
  let(:accumulator) { [] }
  let(:test_job) {
    Helpers::TestJob.new(input: input, accumulator: accumulator,
      transforms: transforms)
  }
  let(:result) { test_job.accumulator }

  describe "NilFields" do
    let(:input) { [{z: "zz"}] }

    let(:transforms) do
      Kiba.job_segment do
        transform Append::NilFields, fields: %i[a b c z]
      end
    end

    let(:expected) { [{z: "zz", a: nil, b: nil, c: nil}] }

    it "adds non-existing fields, populating with nil, while leaving existing fields alone" do
      expect(result).to eq(expected)
    end
  end

  describe "ToFieldValue" do
    let(:input) do
      [
        {name: "Weddy"},
        {name: nil},
        {name: ""}
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Append::ToFieldValue, field: :name, value: " (name)"
      end
    end

    let(:expected) do
      [
        {name: "Weddy (name)"},
        {name: nil},
        {name: ""}
      ]
    end

    it "prepends given value to existing field values, leaving blank values alone" do
      expect(result).to eq(expected)
    end
  end
end
