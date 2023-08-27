# frozen_string_literal: true

RSpec.describe Kiba::Extend::Transforms::Cspace::ConvertToID do
  let(:accumulator) { [] }
  let(:test_job) do
    Helpers::TestJob.new(input: input, accumulator: accumulator,
      transforms: transforms)
  end
  let(:result) { test_job.accumulator }

  let(:input) { [{name: "Weddy1"}] }
  let(:expected) { [{name: "Weddy1", sid: "Weddy13761760099"}] }
  let(:transforms) do
    Kiba.job_segment do
      transform Cspace::ConvertToID, source: :name, target: :sid
    end
  end

  it "inserts CS shortID of given source into target" do
    expect(result).to eq(expected)
  end
end
