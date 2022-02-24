# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Prepend::ToFieldValue do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }

  let(:input) do
    [
      {name: 'Weddy'},
      {name: 'Kernel|Zipper'},
      {name: nil},
      {name: ''}
    ]
  end
  
  let(:transforms) do
    Kiba.job_segment do
      transform Prepend::ToFieldValue, field: :name, value: 'aka: '
    end
  end

  let(:expected) do
    [
      {name: 'aka: Weddy'},
      {name: 'aka: Kernel|Zipper'},
      {name: nil},
      {name: ''}
    ]
  end
  
  it 'transforms as expected' do
    expect(result).to eq(expected)
  end

  context 'with multival' do    
    let(:transforms) do
      Kiba.job_segment do
        transform Prepend::ToFieldValue, field: :name, value: 'aka: ', multival: true, delim: '|'
      end
    end

    let(:expected) do
      [
        {name: 'aka: Weddy'},
        {name: 'aka: Kernel|aka: Zipper'},
        {name: nil},
        {name: ''}
      ]
    end
    
    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end
end

