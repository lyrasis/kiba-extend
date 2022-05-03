# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Merge::ConstantValue do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }

  let(:input) do
    [
      {name: 'Weddy', sex: 'm', source: 'adopted'},
      {name: 'Kernel', sex: 'f', source: 'adopted'}
    ]
  end

  let(:transforms) do
    Kiba.job_segment do
      transform Merge::ConstantValue, target: :species, value: 'guinea fowl'
    end
  end

  let(:expected) do
    [
      {name: 'Weddy', sex: 'm', source: 'adopted', species: 'guinea fowl' },
      {name: 'Kernel', sex: 'f', source: 'adopted', species: 'guinea fowl' }
    ]
  end

  it 'merges specified constant data values into row' do
    expect(result).to eq(expected)
  end
end
