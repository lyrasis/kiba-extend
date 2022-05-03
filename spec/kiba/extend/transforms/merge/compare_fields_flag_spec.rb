# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Merge::CompareFieldsFlag do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }

  let(:input) do
    [
      {id: 'a', pid: 'a', zid: 'a'},
      {id: 'A', pid: 'a', zid: 'a'},
      {id: 'a ', pid: ' a', zid: ' a '},
      {id: '', pid: 'a', zid: 'a'},
      {id: nil, pid: 'a', zid: 'a'},
      {id: '', pid: nil, zid: ''},
    ]
  end

  let(:transforms) do
    Kiba.job_segment do
      transform Merge::CompareFieldsFlag, fields: %i[id pid zid], target: :comp
    end
  end
  
  let(:expected) do
    [
      {id: 'a', pid: 'a', zid: 'a', comp: 'same'},
      {id: 'A', pid: 'a', zid: 'a', comp: 'same'},
      {id: 'a ', pid: ' a', zid: ' a ', comp: 'same'},
      {id: '', pid: 'a', zid: 'a', comp: 'diff'},
      {id: nil, pid: 'a', zid: 'a', comp: 'diff'},
      {id: '', pid: nil, zid: '', comp: 'same'},
    ]
  end

  it 'transforms as expected' do
    expect(result).to eq(expected)
  end
end
