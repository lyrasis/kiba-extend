# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::Delete::FieldValueIfEqualsOtherField do
  let(:accumulator) { [] }
  let(:test_job) {
    Helpers::TestJob.new(input: input, accumulator: accumulator,
      transforms: transforms)
  }
  let(:result) { test_job.accumulator }

  let(:input) do
    [
      {del: "a", compare: "b"},
      {del: "c", compare: "c"}
    ]
  end

  let(:transforms) do
    Kiba.job_segment do
      transform Delete::FieldValueIfEqualsOtherField, delete: :del,
        if_equal_to: :compare
    end
  end

  let(:expected) do
    [
      {del: "a", compare: "b"},
      {del: nil, compare: "c"}
    ]
  end

  it "transforms as expected" do
    expect(result).to eq(expected)
  end

  context "with grouped field(s)" do
    context "where groups are even as expected" do
      let(:input) do
        [
          {row: "1", del: "A;C;d;c;e", compare: "c", grpa: "y;x;w;u;v",
           grpb: "e;f;g;h;i"},
          {row: "2", del: "a;b;c", compare: "a;z;c", grpa: "d;e;f",
           grpb: "g;h;i"},
          {row: "3", del: "a", compare: "a;b", grpa: "d", grpb: "g"},
          {row: "4", del: "a", compare: "b", grpa: "z", grpb: "q"},
          {row: "5", del: "a", compare: "a", grpa: "z", grpb: "q"}
        ]
      end

      let(:transforms) do
        Kiba.job_segment do
          transform Delete::FieldValueIfEqualsOtherField,
            delete: :del,
            if_equal_to: :compare,
            multival: true,
            delim: ";",
            grouped_fields: %i[grpa grpb],
            casesensitive: false
        end
      end

      let(:expected) do
        [
          {row: "1", del: "A;d;e", compare: "c", grpa: "y;w;v", grpb: "e;g;i"},
          {row: "2", del: "b", compare: "a;z;c", grpa: "e", grpb: "h"},
          {row: "3", del: nil, compare: "a;b", grpa: nil, grpb: nil},
          {row: "4", del: "a", compare: "b", grpa: "z", grpb: "q"},
          {row: "5", del: nil, compare: "a", grpa: nil, grpb: nil}
        ]
      end

      it "transforms as expected" do
        expect(result).to eq(expected)
      end
    end

    context "where groups are ragged" do
      let(:input) do
        [
          {del: "A;C;d;e;c", compare: "c", grpa: "y;x;w;u", grpb: "e;f;g;h;i"}
        ]
      end

      let(:transforms) do
        Kiba.job_segment do
          transform Delete::FieldValueIfEqualsOtherField,
            delete: :del,
            if_equal_to: :compare,
            multival: true,
            delim: ";",
            grouped_fields: %i[grpa grpb],
            casesensitive: false
        end
      end

      let(:expected) do
        [
          {del: "A;d;e", compare: "c", grpa: "y;w;u", grpb: "e;g;h"}
        ]
      end

      it "transforms as expected" do
        expect(result).to eq(expected)
      end

      it "outputs warning to STDOUT" do
        # rubocop:todo Layout/LineLength
        msg = /KIBA WARNING: One or more grouped fields \(grpa, grpb\) has different number of values than the others in \{.*\}/
        # rubocop:enable Layout/LineLength
        expect { result }.to output(msg).to_stdout
      end
    end
  end
end
