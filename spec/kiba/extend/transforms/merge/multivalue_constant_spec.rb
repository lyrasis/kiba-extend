# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Merge::MultivalueConstant do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }

  let(:input) do
    [
      {name: 'Weddy'},
      {name: 'NULL'},
      {name: ''},
      {name: nil},
      {name: 'Earlybird;Divebomber'},
      {name: ';Niblet'},
      {name: 'Hunter;'},
      {name: 'NULL;Earhart'}
    ]
  end

  let(:transforms) do
    Kiba.job_segment do
      transform Merge::MultivalueConstant, on_field: :name, target: :species, value: 'guinea fowl', sep: ';', placeholder: 'NULL'
    end
  end
  
  let(:expected) do
    [
      { name: 'Weddy', species: 'guinea fowl' },
      { name: 'NULL', species: 'NULL' },
      { name: '', species: 'NULL' },
      { name: nil, species: 'NULL' },
      { name: 'Earlybird;Divebomber', species: 'guinea fowl;guinea fowl' },
      { name: ';Niblet', species: 'NULL;guinea fowl' },
      { name: 'Hunter;', species: 'guinea fowl;NULL' },
      { name: 'NULL;Earhart', species: 'NULL;guinea fowl' }
    ]
  end
  
  it 'adds specified value to new field once per value in specified field' do
    expect(result).to eq(expected)
  end
end
