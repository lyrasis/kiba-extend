# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::Delete::Fields do
  let(:input) do
    [
      {a: "1", b: "2", c: "3"}
    ]
  end
  let(:accumulator) { [] }
  let(:test_job) {
    Helpers::TestJob.new(input: input, accumulator: accumulator,
      transforms: transforms)
  }
  let(:result) { test_job.accumulator }

  context "with multiple fields in array" do
    let(:transforms) do
      Kiba.job_segment do
        transform Delete::FieldsExcept, fields: %i[a c]
      end
    end

    let(:expected) do
      [
        {a: "1", c: "3"}
      ]
    end

    it "transforms as expected" do
      expect(result).to eq(expected)
    end
  end

  context "with single field given" do
    let(:transforms) do
      Kiba.job_segment do
        transform Delete::FieldsExcept, fields: :b
      end
    end

    let(:expected) do
      [
        {b: "2"}
      ]
    end

    it "transforms as expected" do
      expect(result).to eq(expected)
    end
  end

  context "with keepfields given" do
    let(:transforms) do
      Kiba.job_segment do
        transform Delete::FieldsExcept, keepfields: %i[a c]
      end
    end

    let(:expected) do
      [
        {a: "1", c: "3"}
      ]
    end

    it "transforms as expected" do
      expect(result).to eq(expected)
    end

    it "puts warning to STDOUT" do
      msg = %(#{Kiba::Extend.warning_label}: The `keepfields` keyword is being deprecated in a future version. Change it to `fields` in your ETL code.\n)
      expect { result }.to output(msg).to_stdout
    end
  end

  context "with fields and keepfields given" do
    let(:transforms) do
      Kiba.job_segment do
        transform Delete::FieldsExcept, fields: :b, keepfields: %i[a c]
      end
    end

    let(:expected) do
      [
        {b: "2"}
      ]
    end

    it "transforms as expected" do
      expect(result).to eq(expected)
    end

    it "puts warning to STDOUT" do
      msg = %(#{Kiba::Extend.warning_label}: Do not use both `keepfields` and `fields`. Defaulting to process using `fields`\n)
      expect { result }.to output(msg).to_stdout
    end
  end

  context "with neither fields and keepfields given" do
    let(:transforms) do
      Kiba.job_segment do
        transform Delete::FieldsExcept
      end
    end

    it "puts raises MissingKeywordArgumentError" do
      expect {
        result
      }.to raise_error(Delete::FieldsExcept::MissingKeywordArgumentError)
    end
  end
end
